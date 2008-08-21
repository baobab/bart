class LoadBaseLegacySchema < ActiveRecord::Migration
  def self.up
    return
    database = ActiveRecord::Base.connection.instance_eval('@config')[:database]
    user = ActiveRecord::Base.connection.instance_eval('@config')[:username]
    password = ActiveRecord::Base.connection.instance_eval('@config')[:password]
    file = File.expand_path(RAILS_ROOT + "/db/schema.sql")
#    `mysql -u #{user} --password=#{password} #{database} < #{file}`
    `mysql -u #{user} #{database} < #{file}`
  end

  def self.down
  end
end
