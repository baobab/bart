require File.dirname(__FILE__) + '/../spec_helper'

describe PrescriptionFrequency do
  set_fixture_class :prescription_frequency => PrescriptionFrequency

  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs

	sample({
		:frequency => "Once",
		:frequency_days => 1
	})

  it "should have the table" do
    rx = create_sample(PrescriptionFrequency)
    PrescriptionFrequency.find(:all).should_not be_empty
  end
  
end
