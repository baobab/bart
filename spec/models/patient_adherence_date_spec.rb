require File.dirname(__FILE__) + '/../spec_helper'

describe PatientAdherenceDate do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs

  # If this fails then you need to migrate the views into your test database
  # mysql -u root openmrs_test < db/migrate/patient_start_dates.sql
  it "should have the view" do
    PatientAdherenceDate.find(:all).should_not be_empty
  end
  
  it "should have one set of adherence dates and visit dates for every dispensation"
  it "should use the dispensation date as the visit date"
  it "should add the total remaining pills to the total dispensed pills and divide by the daily consumption to determine the date when drugs will run out"
  it "should use the ministry of health default if the total remaining pills is unknown"
  it "should use the ministry of health default if the total dispensed pills is unknown"
  it "should use the ministry of health default if the daily consumption is unknown"
  it "should use 28 days as the ministry of health default adherence period"
  it "should add 56 days to the date drugs will run out and use that as the default date"
  it "should not consider observations or additional dispensations when calculating the potential default date"
  it "should refer to a patient"
  it "should refer to a drug"
  it "should get reindexed each day"
  # worry about voids
end