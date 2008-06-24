require File.dirname(__FILE__) + '/../spec_helper'

describe PatientIdentifier do
  fixtures :patient_identifier, :patient_identifier_type

  sample({
    :patient_id => 1,
    :identifier => 'SAL 1588',
    :identifier_type => 18,
    :preferred => 0,
    :location_id => 1,
    :creator => 0,
    :date_created => "2000-01-01 00:00:00".to_time,
    :voided => false,
    :voided_by => nil,
    :date_voided => "2000-01-01 00:00:00".to_time,
    :void_reason => nil,
  })

  it "should be valid" do
    patient_identifier = create_sample(PatientIdentifier)
    patient_identifier.should be_valid
  end
   
end
