require File.dirname(__FILE__) + '/../spec_helper'

describe PatientDefaultDate do

  # If this fails then you need to migrate the views into your test database
  it "should have the view" do
    PatientDefaultDate.find(:all).should be_empty
  end

  it "should have a default date for a patient with no dispensation and no outcome observation before the scheduled date"
  it "should not have a default date for a patient with a dispensation before the scheduled date"
  it "should not use non arv dispensations"
  it "should not have a default date for a patient with an outcome observation before the scheduled date"  
  it "should not have a default date for a patient with a continue art treatment observation that does not have the value yes before the scheduled date"  
  it "should not have a default date for a patient with a continue art treatment at this clinic observation that does not have the value yes before the scheduled date"  
  it "should refer to a patient"
  # worry about voids
end
