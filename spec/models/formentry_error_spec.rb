require File.dirname(__FILE__) + '/../spec_helper'

describe FormentryError do

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
