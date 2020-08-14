require 'rubygems'
require 'bundler'

Bundler.require

require './openmensa_bistro_wiesenstein'
run Sinatra::Application
