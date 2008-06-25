require File.dirname(__FILE__) + '/../spec_helper'

describe PatientAddress do
  # You can move this to spec_helper.rb
  set_fixture_class :patient_address => PatientAddress
  fixtures :patient_address

  sample({
    :patient_address_id => 1,
    :patient_id => 1,
    :preferred => false,
    :address1 => '',
    :address2 => '',
    :city_village => '',
    :state_province => '',
    :postal_code => '',
    :country => '',
    :latitude => '',
    :longitude => '',
    :creator => 1,
    :date_created => Time.now,
    :voided => false,
    :voided_by => 1,
    :date_voided => Time.now,
    :void_reason => '',
  })

  it "should be valid" do
    patient_address = create_sample(PatientAddress)
    patient_address.should be_valid
  end
  
end
