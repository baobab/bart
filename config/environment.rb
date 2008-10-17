# Specifies gem version of Rails to use when vendor/rails is not present
# RAILS_GEM_VERSION = '1.1.6'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'fpdf/fpdf'
require 'success'
require 'has_many_through_association_extension'
require 'fixtures'
require 'float'
require 'json/add/rails'
require 'scruffy'
#require 'cached_model'

if RUBY_PLATFORM =~ /java/
  require 'rubygems'
  gem 'ActiveRecord-JDBC'
  require 'jdbc_adapter'
end
Rails::Initializer.run do |config|
  # Skip frameworks you're not going to use
   config.frameworks -= [ :action_web_service ]

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use mem_cache to store sessions
  # config.action_controller.session_store = :mem_cache_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
end

# Include your application configuration below
# ActiveRecord::Base.pluralize_table_names = false

# Foreign key checks use a lot of resources but are useful during development
if ENV['RAILS_ENV'] != 'development'
  ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0")
end

Concept.load_cache rescue nil
health_data = YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['healthdata']
LabParameter.establish_connection(health_data)
LabSample.establish_connection(health_data)
LabTestType.establish_connection(health_data)
LabPanel.establish_connection(health_data)

def yell(msg) 
  # stupid simple logging:
  f = File.open(File.expand_path(File.dirname(__FILE__) + "/../log/yell.log"),"a") 
  f.puts msg 
  f.close
end

class Time; remove_method :to_date ;end #use the rails version

class Date
  # returns last date of previous num month from a_date 
  def subtract_months(num)
    a_date = self
    (1..num).each{|i|
      a_date -= a_date.day
    }
    a_date
  end
end
