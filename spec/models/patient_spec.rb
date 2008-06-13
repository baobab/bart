require File.dirname(__FILE__) + '/../spec_helper'

describe Patient do
  fixtures :patient

  sample({
    :patient_id => 1,
    :gender => '',
    :race => '',
    :birthdate => Time.now.to_date,
    :birthdate_estimated => false,
    :birthplace => '',
    :citizenship => '',
    :mothers_name => '',
    :civil_status => 1,
    :dead => 1,
    :death_date => Time.now,
    :cause_of_death => '',
    :health_district => '',
    :health_center => 1,
    :creator => 1,
    :date_created => Time.now,
    :changed_by => 1,
    :date_changed => Time.now,
    :voided => false,
    :voided_by => 1,
    :date_voided => Time.now,
    :void_reason => '',
  })

  it "should be valid" do
    patient = create_sample(Patient)
    patient.should be_valid
  end
  
end
