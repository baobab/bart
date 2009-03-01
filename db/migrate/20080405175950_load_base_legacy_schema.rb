class LoadBaseLegacySchema < ActiveRecord::Migration
  def self.up
    database = ActiveRecord::Base.connection.instance_variable_get('@config')[:database]
    user = ActiveRecord::Base.connection.instance_variable_get('@config')[:username]
    password = ActiveRecord::Base.connection.instance_variable_get('@config')[:password]
    file = File.expand_path(RAILS_ROOT + "/db/schema.sql")

    `mysql -u #{user} #{"--password=#{password}" if password} #{database} < #{file}`
  end

  def self.down
  end
end
