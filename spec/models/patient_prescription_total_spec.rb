require File.dirname(__FILE__) + '/../spec_helper'

describe PatientPrescriptionTotal do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs

  # If this fails then you need to migrate the views into your test database
  it "should have the view" do
    PatientPrescriptionTotal.find(:all).should_not be_empty
  end  
  
  it "should sum the daily consumption from multiple prescription observations"
  it "should not sum the totals from different patients"
  it "should not sum the totals from different drugs"
  it "should not sum the totals from different dates"  
  it "should refer to a patient"
  it "should refer to a drug"
  it "should get reindexed each day"
  # worry about voids
end