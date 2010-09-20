module Sup
  VERSION = '0.1.6'
  
  GLOBAL_CONFIG_PATH          = '~/.utsup/config.yml'
  GLOBAL_PROJECT_CONFIG_PATH  = '~/.utsup/projects.yml'
  PROJECT_CONFIG_PATH         = '.git/utsup.yml'
  
  API_URL = "https://utsup.heroku.com"
  SIGNUP_URL = "http://www.utsup.com"
  
  class << self
    
    # ===========================
    # Setup
    # ===========================
    
    def sign_in
      render "Please enter your "+"UtSup?".in_magenta+" credentials. " + 
        "Don't have an account yet? ".in_red + 
        "Create one at ".in_green + "#{SIGNUP_URL}".in_blue.as_underline
      
      loop do
        print "Email: ".in_yellow.escape
        email = gets.chomp
        print "Password: ".in_yellow.escape
        system "stty -echo"
        password = gets.chomp
        system "stty echo"
        puts ""
        
        if api_key = Api::User.get_api_key(email, password)
          return api_key
        else
          render "Couldn't find that email/password combo...".in_red
        end
      end
    end
    
    def setup(api_key=nil)
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
      
      FileUtils.mkdir File.dirname(global_config_path) rescue nil
      global_config = Yamlize.new global_config_path
      
      unless global_config['api_key']
        global_config.api_key = api_key || sign_in
        global_config.save
        render "Success!".in_green+" Added API Key to #{GLOBAL_CONFIG_PATH}\n" +
          "  - Lemur Heavy Industries ".in_yellow +
          "http://lemurheavy.com".in_blue.as_underline
      else
        render "You're good to go.".in_green
      end
    end
    
    # ===========================
    # Init
    # ===========================
    
    GIT_HOOKS = {
      "post-checkout" => "sup git checkout $@",
      "post-commit"   => "sup git commit",
      "post-merge"    => "sup git merge $@",
      "post-receive"  => "sup git receive $@"
    }
    
    def init(project_title)      
      # --- project init
      project_title = File.basename(Dir.pwd) if project_title.blank? || project_title == "."
      project = Api::Project.create :title => project_title
      
      if project.valid?
        # add project id to .git
        Yamlize.new File.join(Dir.pwd, PROJECT_CONFIG_PATH) do |project_config|
          project_config.project_id = project.id
        end

        # add project path and id to global project config (for differ)
        Yamlize.new GLOBAL_PROJECT_CONFIG_PATH, Array do |global_project_config|
          global_project_config << {'path'=>Dir.pwd, 'id'=>project.id}
          global_project_config.uniq!
        end

        # --- write git hooks
        GIT_HOOKS.each do |hook, command|
          path = File.join(Dir.pwd, '.git/hooks/', hook)
          exists = File.exists?(path)

          next if exists && File.read(path) =~ /#{Regexp.quote(command)}/

          File.open(path, (exists ? 'a' : 'w'), 0775) do |f|
            f.puts command
          end
        end
                
      else
        #// project creation faild
        render project.errors.full_messages.map &:in_red
      end
    end

    # ===========================
    # Configure
    # ===========================

    def configure
      begin
        global_config = Yamlize.new GLOBAL_CONFIG_PATH
        project_config = Yamlize.new(File.join(Dir.pwd, PROJECT_CONFIG_PATH)) rescue {}
        global_project_config = Yamlize.new GLOBAL_PROJECT_CONFIG_PATH
      
        raise unless global_config['api_key']
      rescue 
        setup
        exit 0
      end
      
      # --- configure API
      Api::Base.project_id = project_config['project_id']
      Api::Base.password = project_config['api_key'] || global_config['api_key']
      Api::Base.site = project_config['domain'] || global_config['domain'] || API_URL
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
                
      when "checkout"
        previous_head = args[1]
        next_head = args[2]
        branch = args[3] == '1'
        
        # TODO: get previous branch name from ref
        
        Api::Status.add :status_type => "StatusCheckout",
          :message => current_branch_name
        
      when "push"
        resp = `git push #{args[1..-1]*' '} 2>&1`
        puts resp
        unless resp =~ /Everything up-to-date/
          Api::Status.add :status_type => "StatusPush", :message => "pushed"
        end
        
      when "receive"
        Api::Status.add :status_type => "StatusReceive",:message => "received"
      
      when "merge"
        Api::Status.add :status_type => "StatusMerge", :message => "merged"
      
      when "commit"
        
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
      
      width = statuses.map{|s| s.to_command_line.gsub(/\\e\[.*?m/,'').size}.max + 2
      line = (" "*width).as_underline.in_white

      render "\nThis is ".in_green+"UtSup?".in_magenta+"#{" with #{name.in_yellow}".in_green if name}:"
      render line
      puts "\n"
      statuses.each do |status|
        render "  "+status.to_command_line
      end
      render line

      puts "\n"
    end
    
    def get_users
      users = Api::User.find :all
      
      puts "#{users.first.company.title} Users:"
      users.each do |user|
        puts user.to_command_line
      end
    end
    
    def socket_error
      render "UtSup? v.#{VERSION} Offline.".in_black.on_red
    end

  end
end