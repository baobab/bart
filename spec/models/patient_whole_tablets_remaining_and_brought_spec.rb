require File.dirname(__FILE__) + '/../spec_helper'

describe PatientWholeTabletsRemainingAndBrought do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs, :prescription_time_periods, :prescription_frequencies, :patient_adherence_dates

  before do
    create_view :patient_dispensations_and_prescriptions
  end

  # If this fails then you need to migrate the views into your test database
  it "should have the view" do
    PatientWholeTabletsRemainingAndBrought.find(:all).should_not be_empty
  end  
end
