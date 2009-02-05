class LoadBaseLegacySchema < ActiveRecord::Migration
  def self.up
    # TODO: figure out why this is only run in test environment
    return unless RAILS_ENV == 'test'
    database = ActiveRecord::Base.connection.instance_eval('@config')[:database]
    user = ActiveRecord::Base.connection.instance_eval('@config')[:username]
    password = ActiveRecord::Base.connection.instance_eval('@config')[:password]
    file = File.expand_path(RAILS_ROOT + "/db/schema.sql")

    `mysql -u #{user} #{"--password=#{password}" if password} #{database} < #{file}`
  end

  def self.down
  end
end
