class AddNonOpenMrsIndices < ActiveRecord::Migration
  def self.up
=begin
    # create indices that we need even though they're not included in OpenMRS    
    add_index :encounter, :encounter_datetime
    add_index :patient_historical_regimens, :patient_id
    add_index :weight_height_for_ages, :age_in_months
    add_index :weight_height_for_ages, :sex
    add_index :global_property, :property
=end   
  end

  def self.down
    remove_index :encounter, :encounter_datetime
    remove_index :patient_historical_regimens, :patient_id
    remove_index :weight_height_for_ages, :age_in_months
    remove_index :weight_height_for_ages, :sex
    remove_index :global_property, :property
  end
end

