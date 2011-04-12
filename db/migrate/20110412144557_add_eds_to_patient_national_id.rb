class AddEdsToPatientNationalId < ActiveRecord::Migration
  def self.up
    add_column :patient_national_id, :eds, :boolean, :default => 0
  end

  def self.down
    remove_column :patient_national_id, :default
    remove_column :patient_national_id, :eds
  end
end
