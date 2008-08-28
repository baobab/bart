require File.dirname(__FILE__) + '/../spec_helper'

describe PrescriptionFrequency do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs, :prescription_frequencies

  it "should have the table" do
    PrescriptionFrequency.find(:all).should_not be_empty
  end
  
end
