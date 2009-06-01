require File.dirname(__FILE__) + '/../spec_helper'

describe UserProperty do

  sample({
    :user_id => 1,
    :property => '',
    :property_value => '',
  })

  it "should be valid" do
    user_property = create_sample(UserProperty)
    user_property.should be_valid
  end
  
end
