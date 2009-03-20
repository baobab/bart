require File.dirname(__FILE__) + '/../spec_helper'

describe PatientAddress do

  it "should create a record" do
    andreas = patient(:andreas)
    PatientAddress.create(andreas.id,"LLH area")
    andreas.physical_address.should == 'LLH area'
  end
end
