$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'active_resource'
require 'yaml'
require 'git'

module Sup
  VERSION = '0.0.1'
  GIT_HOOKS = %w(post-commit post-receive post-merge post-checkout) #TODO: post-rebase?
  
  GLOBAL_CONFIG_PATH = '~/.utsup'
  PROJECT_CONFIG_PATH = 'config/utsup.yml'
  
  HELP_TEXT = <<-eos
=======================================
UtSup Client v.0.0.1
by Nick Merwin (Lemur Heavy Industries)
=======================================

=== Examples:

  sup init this_project_name
  sup in "whatup"
  sup
  sup "just chillin"
  sup out "later"

=== Commands:

  help                      # show this message
  version                   # show version

  init <project name>       # initilize current directory

  "<message>"               # send status update for current project

  (no command)              # get all user's current status

  in                        # check in to project
  out                       # check out of project
  
  nm                        # destroy your last supdate
eos
  
  class << self
    
    # ===========================
    # Init
    # ===========================
    
    def init(args)
      project = Api::Project.create :title => args.first
      
      # --- save project id to config file
      project_config_path = File.join(Dir.pwd, PROJECT_CONFIG_PATH)
      
      unless File.exists?(project_config_path)
        File.open(project_config_path,'w'){|f| f.puts "project_id: #{project.id}"}
      end
      
      # --- write git hooks
      GIT_HOOKS.each do |hook|
        File.open(File.join(Dir.pwd, '.git/hooks/', hook), 'w', 0775) do |f|
          f.write(File.read(File.join(File.dirname(__FILE__),'hooks',hook)))
        end
      end
      
    end

    # ===========================
    # Configure
    # ===========================

    def configure
      global_config_path = File.expand_path(GLOBAL_CONFIG_PATH)
      
      unless File.exists?(global_config_path)
        require 'ftools'
        File.copy File.join(File.dirname(__FILE__), 'config/utsup.sample'), global_config_path
        puts "Initialized ~/.utsup, go change your api_key value!"
      end
      
      global_config = YAML.load_file(global_config_path)
      
      # --- configure API
      Api::Base.password = global_config['api_key']
      Api::Base.site = "http://#{global_config['domain'] || 'utsup.com'}"
      
      # --- configure project
      project_config_path = File.join(Dir.pwd, PROJECT_CONFIG_PATH)
      if File.exists?(project_config_path)
        project_config = YAML.load_file(project_config_path)
        Api::Base.project_id = project_config['project_id']
      end
      
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
          :message => git.branch.name
        
      when "push":
        Api::Status.add :status_type => "StatusPush",
          :message => git.branch.name
          
      when "receive":
        Api::Status.add :status_type => "StatusReceive",
          :message => git.branch.name
      
      when "merge":
        Api::Status.add :status_type => "StatusMerge",
          :message => git.branch.name
      
      when "commit":
        
        commit = git.object('HEAD')
        sha = commit.sha
      
        Api::Status.add :status_type => "StatusCommit", 
          :message => commit.message, 
          :ref => sha, :text => commit.diff_parent
        
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
    
    def get_statuses(name=nil)
      statuses = Api::Status.find :all, :params => {:name => name}
      
      puts "----------------------------------------------------------------------------------"
      puts "This is UtSup#{" with #{name}" if name}:\n"
      statuses.each do |status|
        puts "=> #{status.to_command_line}"
      end
      puts "----------------------------------------------------------------------------------"
    end

  end
  
  # ==============================
  # API's
  # ==============================
  
  module Api
    class Base < ActiveResource::Base
      cattr_accessor :project_id
      self.user = "api"
    end
  
    class Status < Base
      def self.add(attributes)
        create attributes.merge({:project_id => @@project_id})
      end
    end
  
    class Project < Base
    
    end
    
    class User < Base
      def self.check_name(name)
        begin
          get :check_name, :name => name
        rescue ActiveResource::ResourceNotFound
          false
        end
      end
    end
  end
  
  # ==============================
  # Command
  # ==============================
  
  module Command
    class << self
      def run(command, args)
        
        Sup::configure
        
        case command
        
        when "help":
          puts HELP_TEXT

        when "init":
          Sup::init args
          puts "Supified!"

        when "in":
          Sup::check_in args.last
          puts "Checked in."
        when "out":
          Sup::check_out args.last
          puts "Checked out."

        when "git":
          Sup::git_update args
          
        when "nm":
          # destroy last text update
          Sup::undo
          puts "Undid last Supdate."
          
        when "remove"
          File.unlink File.join(Dir.pwd, PROJECT_CONFIG_PATH)
          puts "De-Supified."
          
        when  /.+/:
          if Api::User.check_name(command)
            return Sup::get_statuses(command)
          end
          
          # implicit text update: sup "chillin" 
          Sup::update command
          puts "Supdated."

        else
          # full status check
          Sup::get_statuses
        end
        
      end
    end
  end
  
end


