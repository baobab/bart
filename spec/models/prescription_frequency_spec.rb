require File.dirname(__FILE__) + '/../spec_helper'

describe PrescriptionFrequency do

  it "should have the table" do
    PrescriptionFrequency.find(:all).should_not be_empty
  end
  
end
