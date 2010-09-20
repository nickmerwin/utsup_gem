module Sup
  # ==============================
  # Command Line Controller
  # ==============================
  
  module Command
    class << self
      def run(command, args)
        bench = Time.now

        # no configure
        case command
        when "setup"
          return Sup::setup(args.last)
        end
        
        Sup::configure 
        
        case command
        
        when "help"
          puts HELP_TEXT
          
        when "version"
          puts VERSION
          
        when "init"
          Sup::init args.first
          Differ::restart! # to reload projects.yml
          render "Supified!".in_green

        when "in"
          Sup::check_in args.last
          Differ::start!
          render "Sup'd in.".in_green
          
        when "out"
          Sup::check_out args.last
          Differ::stop!
          puts "Checked out."

        # --- Git -----------------
        when "git"
          Sup::git_update args
        when "push"
          Sup::git_update "push"
          
        when "nm"
          Sup::undo
          render "Undid last Supdate.".in_red
          
        when "remove"
          File.unlink File.join(Dir.pwd, PROJECT_CONFIG_PATH)
          # TODO: remove git hooks
          puts "De-Supified."

        when "users"
          Sup::get_users
          
        when "all"
          Sup::get_statuses :today => true
          
        when "search"
          # TODO: search
          
        when "start"
          Differ::start!
          puts "Started."
        when "stop"
          Differ::stop!
          puts "Stopped."
          
        when  /.+/
          
          # TODO: combine user_name check and supdate into one ActiveResource call -- do name-check & return or supdate on server
          if Api::User.check_name(command)
            Sup::get_statuses :name => command, :today => true
          else
            # implicit text update: sup "chillin" 
            render "Supdated!".in_green if Sup::update(command)
          end
        else
          # full status check
          Sup::get_statuses
        end
        
        # TODO: config file option to set verbosity
        render "UtSup?".in_magenta +
          " v.#{VERSION}".in_green+
          " (#{Time.now - bench}s)".in_white

      rescue SocketError, Errno::ECONNREFUSED
        Sup::socket_error
      end
    end
  end
end