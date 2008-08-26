## the following is outdated. 
## according to soyapi, the success task is run on servers via cron
## crontab entry (of course this is subject to change)
##  * * * * mon-fri /var/www/bart/current/script/runner  -e production 'Success.verify'

namespace :bart do
  namespace :successify do
    desc "Run the successify tasks"  
    task(:all) do
      ENV["RAILS_ENV"] = "production"
      require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
      require 'successify'
      ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
      success = Successify.new
      success.test_scan_every_patient
    end
  end
end			
