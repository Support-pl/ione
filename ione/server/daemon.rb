#!/usr/bin/ruby

require 'daemons'
ROOT = ENV['IONEROOT']
Daemons.run("#{ROOT}/ione.rb", :dir_mode => :system)
