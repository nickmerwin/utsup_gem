require 'rubygems'
require 'daemons'

options = {
  :app_name   => "utsup",
  :backtrace  => true,
  :monitor    => true,
  :multiple   => false,
  :dir_mode   => :normal,
  :dir        => File.join(File.expand_path('~'), '.utsup'),
  :log_output => true
}

Daemons.run(File.join(File.dirname(__FILE__), 'differ_run.rb'), options)