class ChangeTypeOfDailyComsumptionInPatientPrescriptionTotals < ActiveRecord::Migration
  def self.up
    change_column :patient_prescription_totals, :daily_consumption, :float
    
    # recalculate all daily consumptions 
    PatientPrescriptionTotal.reset
  end

  def self.down
    change_column :patient_prescription_totals, :daily_consumption, :integer
  end
end
