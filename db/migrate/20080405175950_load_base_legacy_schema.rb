class LoadBaseLegacySchema < ActiveRecord::Migration
  def self.up
    database = ActiveRecord::Base.connection.instance_eval('@config')[:database]
    user = ActiveRecord::Base.connection.instance_eval('@config')[:username]
    file = File.expand_path(RAILS_ROOT + "/db/schema.sql")
    `mysql -u #{user} #{database} < #{file}`
  end

  def self.down
  end
end
