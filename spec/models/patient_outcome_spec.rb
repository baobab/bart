require File.dirname(__FILE__) + '/../spec_helper'

describe PatientOutcome do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs

  # If this fails then you need to migrate the views into your test database
  it "should have the view" do
    PatientOutcome.find(:all).should_not be_empty
  end
    
  it "should not include voided outcomes"
  it "should have an outcome for each outcome observation"
  it "should have an outcome for every arv dispensation"
  it "should use the default date as the outcome date if the patient is a defaulter"
  it "should have an outcome if the patient is not continuing treatment at the current clinic"
  it "should have an outcome if the patient is not continuing treatment"
  # worry about voids
end