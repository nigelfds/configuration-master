$LOAD_PATH << File.dirname(__FILE__)
BUILD_DIR = "build"

require "colorize"
require "rake/clean"
require "tasks/aws"
require "tasks/package"
require "rspec/core/rake_task"

CLEAN.include(BUILD_DIR)

RSpec::Core::RakeTask.new(:spec)

task(:default) {|t| puts "WIP !! to be defined"}

