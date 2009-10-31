module Sup
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
          puts "You're not in a Sup project.  Run 'sup init' to add this directory."
          return
        end
        
        create attributes.merge({:project_id => @@project_id, :branch => Sup::current_branch_name, :version => VERSION})
        
      rescue ActiveResource::ResourceNotFound
        puts "Your project_id was invalid, check #{PROJECT_CONFIG_PATH}"
      rescue SocketError
        Sup::socket_error
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
end