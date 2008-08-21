require File.dirname(__FILE__) + '/../spec_helper'

describe PatientPrescription do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs

  # If this fails then you need to migrate the views into your test database
  # mysql -u root openmrs_test < db/migrate/patient_prescriptions.sql
  it "should have the view" do
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
end