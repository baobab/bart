require File.dirname(__FILE__) + '/../spec_helper'

describe PrescriptionTimePeriod do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs

  # If this fails then you need to migrate the views into your test database
  it "should have the view" do
    PrescriptionTimePeriod.find(:all).should_not be_empty
  end
end