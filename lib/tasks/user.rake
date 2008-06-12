namespace :db do
  namespace :user do
    desc "Create a user in the database and grant all permissions. USER,PASSWORD can be used from the command line or the task will prompt you."
    task :create => :environment do
      # We need to establish a connection using the root user   
      root_user = ENV['USER']
      root_pass = ENV['PASSWORD']
      unless (root_user)
        puts "User:"
        root_user = STDIN.gets.strip()
      end      
      unless (root_pass)
        puts "Password:"
        root_pass = STDIN.gets.strip()
      end                     
      raise "You must specify a user name and password for the root user" if root_user.blank? || db_pass.blank?       
      
      db_user = ""
      db_pass = ""
      database = ""
      
      # Add the user
      ActiveRecord::Base.connection.execute "GRANT ALL ON #{database}.* TO #{db_user} IDENTIFIED BY '#{db_pass}'" 
    end
  end  
end	