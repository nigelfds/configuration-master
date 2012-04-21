$LOAD_PATH << File.dirname(__FILE__)
BUILD_DIR = "build"

require 'colorize'
require 'rake/clean'
require 'tasks/aws'

CLEAN.include(BUILD_DIR)

task(:default) {|t| puts "WIP !! to be defined"}

