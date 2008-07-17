ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec/rails/story_adapter'

dir = File.dirname(__FILE__)
Dir[File.expand_path("#{dir}/steps/*.rb")].uniq.each do |file|
  require file
end

def run_local_story(filename, options={})
  run File.join(File.dirname(__FILE__), 'stories', filename), options
end

def login_user(username, password, location) 
  post "/user/login", :user => { :username => username, :password => password }, 
    :location => location
end