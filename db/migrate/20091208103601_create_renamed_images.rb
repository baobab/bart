class CreateRenamedImages < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS renamed_images;
EOF
    create_table :renamed_images do |t|
      t.string :md5sum, :limit => 32
      t.integer :arv_number
      t.integer :page_number, :limit => 2
      t.timestamps
    end

    add_index :renamed_images, :md5sum, :unique => true
    add_index :renamed_images, :arv_number
  end

  def self.down
    drop_table :renamed_images
  end
end
