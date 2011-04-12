class AddEdsToPatientNationaliId < ActiveRecord::Migration
  def self.up
    add_column :patient_nationali_id, :eds, :boolen, :default => 0
  end

  def self.down
    remove_column :patient_nationali_id, :default
    remove_column :patient_nationali_id, :eds
  end
end
