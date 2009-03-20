require File.dirname(__FILE__) + '/../spec_helper'

describe PatientFirstLineRegimenDispensation do

  # If this fails then you need to migrate the views into your test database
  it "should have the view" do
    PatientFirstLineRegimenDispensation.find(:all).should_not be_empty
  end
  
  it "should have a dispensation for patients receiving first line regimens" 
  it "should not have a dispensation for patients receiving first line alternative regimens" 
  it "should not have a dispensation for patients on unknown regimens" 
  it "should have multiple entries for patients with multiple dispensations" 
  it "should have a dispensation for first line regimen even when other drugs are included" 
  it "should have a dispensation for first line regimen even when and it matches both first and second line regimen"
  it "should refer to a patient"
  it "should refer to an encounter"
  
  # worry about voids
  # worry about retired
  # worry about location
end
