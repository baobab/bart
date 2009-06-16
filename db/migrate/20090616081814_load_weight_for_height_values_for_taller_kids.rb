class LoadWeightForHeightValuesForTallerKids < ActiveRecord::Migration
  def self.up
    require 'fastercsv'
    weight_for_height_values = FasterCSV.read('db/migrate/weight_for_height_over_84.5cm.csv')
    weight_for_height_values.each do |height,weight|
      [0,1].each do |sex_number|
        WeightForHeight.create(:supine_cm => height, 
                               :median_weight_height => weight, 
                               :sex => sex_number)
      end
    end
  end

  def self.down
    require 'fastercsv'
    weight_for_height_values = FasterCSV.read('db/migrate/weight_for_height_over_84.5cm.csv')
    weight_for_height_values.each do |height,weight|
      WeightForHeight.destroy_all(['supine_cm = ?', height])
    end
  end
end
