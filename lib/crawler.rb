require 'bundler'
Bundler.require

Crawler = Module.new

require_relative 'extensions/moped'
require_relative 'crawler/persistence'
require_relative 'crawler/indexes'
require_relative 'crawler/worker'
require_relative 'crawler/task'
require_relative 'crawler/stats'

tasks = File.expand_path('../crawler/task/*.rb', __FILE__)
Dir[tasks].each {|file| require file }
