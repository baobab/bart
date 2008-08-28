require File.dirname(__FILE__) + '/../spec_helper'

describe PatientPrescription do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order,
           :orders, :order_type, :concept, :concept_class, :concept_set, :obs, :prescription_frequencies, :prescription_time_periods

  it "should have the view" do
    create_view
    rxes = PatientPrescription.find(:all)
    puts "found #{rxes.size} patient rx'es"
    PatientPrescription.find(:all).should_not be_empty
  end

  it "should not include voided prescriptions"
  it "should have a record for cotrimoxazole prescriptions"
  it "should have a record for insecticide treated nets"
  it "should include the prescription time period from the encounter"
  it "should use the last prescription time period if there are multiples"
  it "should calculate the quantity needed for the prescription time period"
  it "should calculate the daily consumption based on the frequency and the dose amount"
  it "should not include information about whole tablets remaining and brought"

  def create_view
    ActiveRecord::Base.connection.execute "DROP VIEW patient_prescriptions"
    ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_prescriptions (patient_id, encounter_id, prescription_datetime, drug_id, frequency, dose_amount, time_period, quantity, daily_consumption) AS
  SELECT encounter.patient_id, 
         encounter.encounter_id, 
         prescribed_dose.obs_datetime, 
         prescribed_dose.value_drug,
         prescribed_dose.value_text,
         prescribed_dose.value_numeric,
         prescribed_time_period.value_text,
         (prescribed_dose.value_numeric * (prescription_time_periods.time_period_days / prescription_frequencies.frequency_days)),
         (prescribed_dose.value_numeric / prescription_frequencies.frequency_days)
  FROM encounter
  INNER JOIN obs AS prescribed_dose ON 
    prescribed_dose.concept_id = 375 AND 
    prescribed_dose.encounter_id = encounter.encounter_id AND 
    prescribed_dose.value_drug IS NOT NULL AND 
    prescribed_dose.voided = 0
  INNER JOIN obs AS prescribed_time_period ON 
    prescribed_time_period.concept_id = 345 AND
    prescribed_time_period.encounter_id = encounter.encounter_id AND 
    prescribed_time_period.voided = 0
  INNER JOIN prescription_frequencies ON prescription_frequencies.frequency = prescribed_dose.value_text  
  INNER JOIN prescription_time_periods ON prescription_time_periods.time_period = prescribed_time_period.value_text  
  WHERE encounter.encounter_type = 2;
EOF
  end
end

