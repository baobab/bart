class CreateWeightForHeights < ActiveRecord::Migration
  def self.up
    drop_table :weight_for_heights
    create_table :weight_for_heights  do |t|
      t.float :supine_cm
      t.float :median_weight_height
      t.float :standard_low_weight_height
      t.float :standard_high_weight_height
      t.integer :sex, :limit => 6
    end
  end

  def self.down
    drop_table :weight_for_heights
  end
end
