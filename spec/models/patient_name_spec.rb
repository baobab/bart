require File.dirname(__FILE__) + '/../spec_helper'

describe PatientName do

  sample({
    :preferred => true,
    :patient_id => 1,
    :prefix => "Dr.",
    :given_name => "Andreas",
    :middle_name => nil,
    :family_name_prefix => nil, 
    :family_name => "Jahn",
    :family_name2 => nil,
    :family_name_suffix => nil,
    :degree => nil, 
    :creator => 1,
    :date_created => "2007-01-01 00:00:00".to_time,
  })

  it "should be valid" do
    patient_name = create_sample(PatientName)
    patient_name.should be_valid
  end
   
end
