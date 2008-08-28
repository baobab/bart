require File.dirname(__FILE__) + '/../spec_helper'

describe PatientDispensationAndPrescription do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs

  # If this fails then you need to migrate the views into your test database
  it "should have the view" do
    PatientDispensationAndPrescription.find(:all).should_not be_empty
  end
  
  it "should have one row for each drug even if there are multiple drug orders for that drug"
  it "should use all of the drug orders for arv drugs from the encounter"
  it "should include the whole tablets remaining and brought observation from the same visit for the same drug"
  it "should not require the whole tablets remaining and brought observation to be present"
  it "should include the prescription totals for the drug"
  it "should not require a prescription to list the dispensation"
  # worry about voids    
  # worry about the documentation
end