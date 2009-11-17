# TODO: testing suite
# TODO: proxy option

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'active_resource'
require 'git'

require 'terminal_markup'

require 'sup/base'
require 'sup/yamlize'
require 'sup/differ/differ'
require 'sup/api'
require 'sup/command'
require 'sup/help'

module Kernel
  def render(string)
    puts string.escape
  end
end