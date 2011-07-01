class AddCreatorToPatientNationalId < ActiveRecord::Migration
  def self.up
    add_column :patient_national_id, :creator, :int
  end

  def self.down
    remove_column :patient_national_id, :creator
  end
end
