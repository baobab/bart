require File.dirname(__FILE__) + '/../spec_helper'

describe PatientAddress do
  # You can move this to spec_helper.rb
  set_fixture_class :patient_address => PatientAddress
  fixtures :patient_address, :patient

  it "should create a record" do
    andreas = patient(:andreas)
    PatientAddress.create(andreas.id,"LLH area")
    andreas.physical_address.should == 'LLH area'
  end
end
