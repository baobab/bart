class CreateUserMastercards < ActiveRecord::Migration
=begin
  def self.down
    drop_table :user_mastercards
  end

  def self.up
    create_table :user_mastercards do |t|
      t.integer :user_id
      t.string :arv_number
      t.timestamps
    end

    add_index :user_mastercards, :arv_number, :unique => true
    add_index :user_mastercards, :user_id
  end
=end
end
