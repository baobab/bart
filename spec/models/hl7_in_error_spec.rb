require File.dirname(__FILE__) + '/../spec_helper'

describe Hl7InError do
  # You can move this to spec_helper.rb
  set_fixture_class :hl7_in_error => Hl7InError
  fixtures :hl7_in_error

  sample({
    :hl7_in_error_id => 1,
    :hl7_source => 1,
    :hl7_source_key => '',
    :hl7_data => '',
    :error => '',
    :error_details => '',
    :date_created => Time.now,
  })

  it "should be valid" do
    hl7_in_error = create_sample(Hl7InError)
    hl7_in_error.should be_valid
  end
  
end
