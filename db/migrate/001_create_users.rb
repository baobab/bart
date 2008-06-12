class CreateUsers < ActiveRecord::Migration
  def self.up
    unless User.find_by_username("Administrator")
      ActiveRecord::Base.connection.update "SET FOREIGN_KEY_CHECKS = 0"
      admin = User.create(
        :username => "Administrator",
        :password => "password",
        :voided => 0 )
      ActiveRecord::Base.connection.update "SET FOREIGN_KEY_CHECKS = 1"
    end      
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
