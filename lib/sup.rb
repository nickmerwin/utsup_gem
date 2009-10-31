# TODO: testing suite

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'active_resource'
require 'git'

require 'sup/yamler'

require 'sup/differ/differ'
require 'sup/api'
require 'sup/command'

module Sup
  VERSION = '0.1.0'
  GIT_HOOKS = %w(post-commit post-receive post-merge post-checkout) #TODO: post-rebase?
  
  GLOBAL_CONFIG_PATH          = '~/.utsup/config.yml'
  GLOBAL_PROJECT_CONFIG_PATH  = '~/.utsup/projects.yml'
  PROJECT_CONFIG_PATH         = '.git/utsup.yml'
  
  class << self
    
    # ===========================
    # Setup
    # ===========================
    
    def setup(api_key="your api key here")
      require 'fileutils'
      
      # --- global init
      global_config_path = File.expand_path(GLOBAL_CONFIG_PATH)
      
      # for back-compat with old config file
      oldpath = File.dirname(global_config_path)
      if File.exists?(oldpath) && !File.directory?(oldpath)
        FileUtils.mv oldpath, oldpath+'.bak'
        FileUtils.mkdir File.dirname(global_config_path)
        FileUtils.mv oldpath+'.bak', global_config_path
      end
      
      unless File.exists?(global_config_path)
        FileUtils.mkdir File.dirname(global_config_path)
        FileUtils.copy File.join(File.dirname(__FILE__), 'config/utsup.sample'), global_config_path
        
        Yamler.new global_config_path  do |global_config|
          global_config.api_key = api_key
        end
        
        puts "Initialized ~/.utsup/config.yml"
        
      else
        puts "You're good to go."
      end
    end
    
    # ===========================
    # Init
    # ===========================
    
    def init(project_title)
      
      # --- project init
      project_title = File.basename(Dir.pwd) if project_title.blank? || project_title == "."
      project = Api::Project.create :title => project_title
      
      # add project id to .git
      Yamler.new File.join(Dir.pwd, PROJECT_CONFIG_PATH) do |project_config|
        project_config.project_id = project.id
      end
      
      # add project path and id to global project config (for differ)
      Yamler.new GLOBAL_PROJECT_CONFIG_PATH, Array do |global_project_config|
        global_project_config << {'path'=>Dir.pwd, 'id'=>project.id}
      end
      
      # --- write git hooks
      #TODO: option to manually add hooks if they already have some...
      GIT_HOOKS.each do |hook|
        path = File.join(Dir.pwd, '.git/hooks/', hook)
        hook_cmd = File.read(File.join(File.dirname(__FILE__),'hooks',hook))
        
        if File.exists?(path)
          puts "You already have a git hook here: #{path}"
          puts "Please make sure it's executable add this to it:"
          puts hook_cmd + "\n"
          next
        end
        
        File.open(path, 'w', 0775) do |f|
          f.write hook_cmd
        end
      end
      
    end

    # ===========================
    # Configure
    # ===========================

    def configure
      
      global_config = Yamler.new GLOBAL_CONFIG_PATH
      project_config = Yamler.new(File.join(Dir.pwd, PROJECT_CONFIG_PATH)) rescue {}
      global_project_config = Yamler.new GLOBAL_PROJECT_CONFIG_PATH
      
      unless global_config['api_key']
        puts "You need to run 'sup setup <api_key>' first, thanks!"
        exit 0
      end
      
      # --- configure API
      Api::Base.project_id = project_config['project_id']
      Api::Base.password = project_config['api_key'] || global_config['api_key']
      Api::Base.site = "http://#{project_config['domain'] || global_config['domain'] || 'utsup.com'}"
    end
    
    # ===========================
    # Check In/Out
    # ===========================
    def check_in(message)
      Api::Status.add :status_type => "StatusIn", :message => message
    end
    
    def check_out(message)
      Api::Status.add :status_type => "StatusOut", :message => message
    end
    
    # ===========================
    # undo
    # ===========================    
    
    def undo
      Api::Status.delete :undo
    end
    
    # ===========================
    # Git Update 
    # ===========================
  
    def current_branch_name
      `git branch 2> /dev/null | grep -e ^*`[/^\* (.*?)\n/,1]
    end
  
    def git_update(*args)
      git = Git.open(Dir.pwd)

      args.flatten!
      
      case args.first.strip
                
      when "checkout":
        previous_head = args[1]
        next_head = args[2]
        branch = args[3] == '1'
        
        # TODO: get previous branch name from ref
        
        Api::Status.add :status_type => "StatusCheckout",
          :message => current_branch_name
        
      when "push":
        resp = `git push #{args[1..-1]*' '} 2>&1`
        puts resp
        unless resp =~ /Everything up-to-date/
          Api::Status.add :status_type => "StatusPush", :message => "pushed"
        end
        
      when "receive":
        Api::Status.add :status_type => "StatusReceive",:message => "received"
      
      when "merge":
        Api::Status.add :status_type => "StatusMerge", :message => "merged"
      
      when "commit":
        
        commit = git.object('HEAD')
        sha = commit.sha
      
        Api::Status.add :status_type => "StatusCommit", 
          :message => commit.message, 
          :ref => sha, :text => `git diff HEAD~ HEAD`
                  
      else
        puts "WTF git status is that?"
      end
        
    end

    # ===========================
    # Update
    # ===========================
        
    def update(message)
      Api::Status.add :status_type => "StatusUpdate", :message => message
    end
    
    # ===========================
    # Get Statuses
    # ===========================
    
    def get_statuses(opts={})
      name = opts[:name]
      
      statuses = Api::Status.find :all, :params => {
        :name => name, 
        :today => opts[:today]
      }
      
      puts "----------------------------------------------------------------------------------"
      puts "This is UtSup#{" with #{name}" if name}:\n"
      statuses.each do |status|
        puts "=> #{status.to_command_line.escape}"
      end
      puts "----------------------------------------------------------------------------------"
    end
    
    def get_users
      users = Api::User.find :all
      
      puts "#{users.first.company.title} Users:"
      users.each do |user|
        puts user.to_command_line
      end
    end
    
    def socket_error
      puts "UtSup? v.#{VERSION} Offline."
    end

  end
end


class String
  def escape
    eval '"'+ gsub(/\"/,'\"') + '"'
  end
end