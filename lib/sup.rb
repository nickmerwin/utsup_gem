$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'active_resource'
require 'yaml'
require 'git'

module Sup
  VERSION = '0.0.8'
  GIT_HOOKS = %w(post-commit post-receive post-merge post-checkout) #TODO: post-rebase?
  
  GLOBAL_CONFIG_PATH = '~/.utsup'
  PROJECT_CONFIG_PATH = '.git/utsup.yml'
  
  HELP_TEXT = <<-eos
=======================================
UtSup Client v.0.0.1
by Nick Merwin (Lemur Heavy Industries)
=======================================

=== Examples:
  sup setup

  sup init
  sup in "whatup"
  sup
  sup "just chillin"
  sup out "later"

=== Commands:

  help                      # show this message
  version                   # show version
  
  setup                     # initializes global config file

  init <project name>       # initilize current directory

  "<message>"               # send status update for current project
  nm                        # destroy your last supdate
  
  (no command)              # get all user's current status
  all                       # get all user's statuses over the past day

  in "<message>"            # check in to project
  out "<message>"           # check out of project
  
  users                     # get list of users in company
  <user name>               # get last day's worth of status updates from specified user
  
  push                      # triggers a git push + update
eos
  
  class << self
    
    def setup
      # --- global init
      global_config_path = File.expand_path(GLOBAL_CONFIG_PATH)
      
      unless File.exists?(global_config_path)
        require 'ftools'
        File.copy File.join(File.dirname(__FILE__), 'config/utsup.sample'), global_config_path
        puts "Initialized ~/.utsup, go change your api_key value."
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
      
      project_config_path = File.join(Dir.pwd, PROJECT_CONFIG_PATH)
      
      project_config = YAML.load_file(project_config_path) rescue {}
      project_config["project_id"] = project.id
      File.open(project_config_path,'w'){|f| YAML.dump( project_config, f )}
      
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
      global_config = YAML.load_file(global_config_path)
      
      project_config_path = File.join(Dir.pwd, PROJECT_CONFIG_PATH)
      project_config = YAML.load_file(project_config_path) rescue {}
      
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
        unless self.project_id
          puts "You're not in a project."
          return
        end
        
        create attributes.merge({:project_id => @@project_id, :branch => Sup::current_branch_name})
        
      rescue ActiveResource::ResourceNotFound
        puts "Your project_id was invalid, check #{PROJECT_CONFIG_PATH}"
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
  # Command Line Controller
  # ==============================
  
  module Command
    class << self
      def run(command, args)
        
        # no configure
        case command
        when "setup":
          return Sup::setup
        end
        
        Sup::configure 
        
        case command
        
        when "help":
          puts HELP_TEXT
          
        when "version":
          puts VERSION
          
        when "init": 
          Sup::init args.first
          puts "Supified!"

        when "in":
          Sup::check_in args.last
          puts "Checked in."
        when "out":
          Sup::check_out args.last
          puts "Checked out."

        # --- Git -----------------
        when "git":
          Sup::git_update args
        when "push":
          Sup::git_update "push"
          
        when "nm":
          Sup::undo
          puts "Undid last Supdate."
          
        when "remove":
          File.unlink File.join(Dir.pwd, PROJECT_CONFIG_PATH)
          # TODO: remove git hooks
          puts "De-Supified."

        when "users":
          Sup::get_users
          
        when "all":
          # TODO: show all today
          Sup::get_statuses :today => true
          
        when "search":
          # TODO: search
          
        when  /.+/:
          if Api::User.check_name(command)
            Sup::get_statuses :name => command, :today => true
            return 
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


class String
  def escape
    eval '"'+ gsub(/\"/,'\"') + '"'
  end
end