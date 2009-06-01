require File.dirname(__FILE__) + '/../spec_helper'

describe PatientPrescriptionTotal do

  sample({
      :patient_id => 1, 
      :drug_id => 5, 
      :prescription_date => "2007-03-05", 
      :daily_consumption => 2
  })

  # If this fails then you need to migrate the views into your test database
  it "should have the view" do
    prx = create_sample(PatientPrescriptionTotal)
    PatientPrescriptionTotal.find(:all).should_not be_empty
  end  

end
