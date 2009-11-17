=begin
======
Yamlize
======

by Nick Merwin 10.31.09

Why? Bored with writing yaml loaders + dumpers.
=end

require 'yaml'
class Yamlize
  attr_reader :path, :attributes
  
  def initialize(path, type=Hash, &block)
    @path = File.expand_path path
    File.open(@path,'w'){} unless File.exists?(@path)
    @attributes = YAML.load_file(@path) || type.new
    
    if block_given?
      yield self
      save
    end
  rescue Errno::ENOTDIR
    raise "Path invalid."
  rescue Errno::ENOENT
    raise "Path invalid."
  end
  
  def method_missing(name, *args, &block)
    if attribute = name.to_s[/(.*?)=/,1]
      @attributes[attribute] = args.first
      return
    end
    
    begin
      if !@attributes[name.to_s].nil?
        return @attributes[name.to_s]
      end
    rescue TypeError
    end
    
    if @attributes.respond_to?(name)
      return @attributes.send name, *args, &block
    end
    
    super name, *args
  end
  
  def save
    File.open(@path,'w'){|f| YAML.dump @attributes, f}
  end
end

module YamlizeMethods
  def yamlize(path, &block)
    Yamlize.new path, self.class, &block
  end
end

class Object
  include YamlizeMethods
end