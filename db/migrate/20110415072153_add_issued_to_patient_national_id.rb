class AddIssuedToPatientNationalId < ActiveRecord::Migration
  def self.up
    add_column :patient_national_id, :issued_to, :text
  end

  def self.down
    remove_column :patient_national_id, :issued_to
  end
end
