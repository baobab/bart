require File.dirname(__FILE__) + '/../spec_helper'

describe PatientWholeTabletsRemainingAndBrought do
  before do
    create_view :patient_dispensations_and_prescriptions
  end

  # If this fails then you need to migrate the views into your test database
  it "should have the view" do
    PatientWholeTabletsRemainingAndBrought.find(:all).should_not be_empty
  end  
end
