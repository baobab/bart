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
  
  it "should sum the daily consumption from multiple prescription observations"
  it "should not sum the totals from different patients"
  it "should not sum the totals from different drugs"
  it "should not sum the totals from different dates"  
  it "should refer to a patient"
  it "should refer to a drug"
  it "should get reindexed each day"
  # worry about voids
end
