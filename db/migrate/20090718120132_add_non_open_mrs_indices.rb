class AddNonOpenMrsIndices < ActiveRecord::Migration
  def self.up
    # create indices that we need even though they're not included in OpenMRS    
    add_index :encounter, :encounter_datetime rescue nil
    add_index :patient_historical_regimens, :patient_id rescue nil
    add_index :weight_height_for_ages, :age_in_months rescue nil
    add_index :weight_height_for_ages, :sex rescue nil
    add_index :global_property, :property rescue nil
  end

  def self.down
    remove_index :encounter, :encounter_datetime rescue nil
    remove_index :patient_historical_regimens, :patient_id rescue nil
    remove_index :weight_height_for_ages, :age_in_months rescue nil
    remove_index :weight_height_for_ages, :sex rescue nil
    remove_index :global_property, :property rescue nil
  end
end

