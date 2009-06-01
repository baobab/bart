class LoadBaseLegacySchema < ActiveRecord::Migration
  def self.up
    database = ActiveRecord::Base.connection.instance_variable_get('@config')[:database]
    user = ActiveRecord::Base.connection.instance_variable_get('@config')[:username]
    password = ActiveRecord::Base.connection.instance_variable_get('@config')[:password]
    file = File.expand_path(RAILS_ROOT + "/db/schema.sql")

    `mysql -u #{user} #{"--password=#{password}" if password} #{database} < #{file}`

    execute "ALTER TABLE users DROP FOREIGN KEY `user_creator`"
    # create first user
    salt = User.random_string(10)
    password = User.encrypt(User.random_string(8), salt)

    user = User.create!(:salt => salt, :password => password, :creator => '1', :first_name => 'Baobab', :last_name => 'Admin', :system_id => 'Baobab Admin', :username => 'baobadmin')
    user.update_attribute(:creator, user.id)

    execute "alter table users add CONSTRAINT `user_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)"
  end

  def self.down
    ActiveRecord::Base.connection.tables.each{ |t| drop_table t.to_sym unless ["schema_migrations", "migrations_info"].include? t }
  end
end
