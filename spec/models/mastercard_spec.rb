require File.dirname(__FILE__) + '/../spec_helper'

describe Mastercard do
  # You can move this to spec_helper.rb
  set_fixture_class :patient => Mastercard
  fixtures :patient

  sample({
    :patient_id => 1,
    :gender => '',
    :race => '',
    :birthdate => Time.now.to_date,
    :birthdate_estimated => false,
    :birthplace => '',
    :tribe => 1,
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
    mastercard = create_sample(Mastercard, patient(:andreas))
    mastercard.should be_valid
  end
  
end
