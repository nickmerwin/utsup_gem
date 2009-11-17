#TODO: check git status for added un-tracked files

module Sup
  module Differ
    INTERVAL = 300
    # TODO: pull interval out of config.yml?
    
    class << self
      def run
        @projects = Project.all

        loop do
          @projects.map &:diff!
          sleep INTERVAL
        end
      end

      def start!
        `ruby #{File.join(File.expand_path(File.dirname(__FILE__)),'differ_control.rb')} start`
      end

      def stop!
        `ruby #{File.join(File.expand_path(File.dirname(__FILE__)),'differ_control.rb')} stop`
      end
      
      def restart!
        stop! && start!
      end
    end
  end
  
  # TODO: marshal dump these directly to yaml? or store in sqlite db
  class Project
    attr_accessor :current_diff
    def initialize(id, path)
      @id, @path = id, path
      @current_diff = ""
      @current_changed_files = {}
    end
    
    def diff!
      # figure out which specific files have changed since the last diff
      
      @changed_files = []
      @current_diffs = []
      
      Dir.chdir @path
      diff = `git diff`
      
      if diff != @current_diff
        @current_diff = diff
        
        # get array of changed files from git diff
        `git diff --stat`.scan(/^ (.*?)\s{1,}\|/m).flatten.each do |file|
          
          # get specific diff for file
          file_diff = `git diff #{file}`
          
          # if different from previous diff, store path and diff
          if @current_changed_files[file] != file_diff
            @current_changed_files[file] = file_diff
            @changed_files << file
            @current_diffs << file_diff
          end
        end
        
        supdate! unless @changed_files.empty?
      end
    end
    
    def supdate!
      Sup::configure
      Sup::Api::Status.add :status_type => "StatusDiff", :message => @changed_files*', ',
        :text => @current_diffs*'\n'
    end
    
    class << self
      def all
        [].yamlize(GLOBAL_PROJECT_CONFIG_PATH).map do |project_config|
          new project_config['id'], project_config['path']
        end
      end
    end
    
  end
end