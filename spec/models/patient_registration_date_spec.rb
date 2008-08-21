require File.dirname(__FILE__) + '/../spec_helper'

describe PatientRegistrationDate do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs

  # If this fails then you need to migrate the views into your test database
  # mysql -u root openmrs_test < db/migrate/patient_registration_dates.sql
  it "should have the view" do
    PatientRegistrationDate.find(:all).should_not be_empty
  end
  
  it "should use any initial ARV dispensation date for this location as the registration date"
  it "should not use dispensation encounters where no ARV drugs were dispensed"
  it "should have multiple registration dates if there are multiple locations and the patient has trasferred"
  it "should not have more than one registration date per location"
  it "should not include patients that have never received ARV drugs"
  
  # should we worry about arv numbers?
  
  
  
end