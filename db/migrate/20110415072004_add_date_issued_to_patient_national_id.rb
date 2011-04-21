class AddDateIssuedToPatientNationalId < ActiveRecord::Migration
  def self.up
    add_column :patient_national_id, :date_issued, :datetime
  end

  def self.down
    remove_column :patient_national_id, :date_issued
  end
end
