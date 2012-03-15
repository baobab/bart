require File.dirname(__FILE__) + '/../spec_helper'

describe FormentryError do
  # You can move this to spec_helper.rb
  set_fixture_class :formentry_error => FormentryError
  fixtures :formentry_error

  sample({
    :formentry_error_id => 1,
    :form_data => '',
    :error => '',
    :error_details => '',
    :creator => 1,
    :date_created => Time.now,
  })

  it "should be valid" do
    formentry_error = create_sample(FormentryError)
    formentry_error.should be_valid
  end
  
end
