require File.dirname(__FILE__) + '/../spec_helper'

describe PrescriptionTimePeriod do

  it "should find some data" do
    PrescriptionTimePeriod.find(:all).should_not be_empty
  end
end
