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
        when "setup":
          return Sup::setup args.last
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
          Differ::start!
          puts "Checked in."
          
        when "out":
          Sup::check_out args.last
          Differ::stop!
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
          Sup::get_statuses :today => true
          
        when "search":
          # TODO: search
          
        when "start"
          Differ::start!
          puts "Started."
        when "stop"
          Differ::stop!
          puts "Stopped."
          
        when  /.+/:
          
          # TODO: combine user_name check and supdate into one ActiveResource call -- do name-check & return or supdate on server
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
        
        # TODO: config file option to set verbosity
        puts "UtSup? v.#{VERSION} (#{Time.now - bench}s)"

      rescue SocketError
        Sup::socket_error
      end
    end
  end
end