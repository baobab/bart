require File.dirname(__FILE__) + '/../spec_helper'

describe GlobalProperty do
  # You can move this to spec_helper.rb
  set_fixture_class :global_property => GlobalProperty
  fixtures :global_property

  sample({
    :id => 1,
    :property => '',
    :property_value => '',
  })

  it "should be valid" do
    global_property = create_sample(GlobalProperty)
    global_property.should be_valid
  end
  
  it "should display global property as a string" do
    global_property(:global_property_00003).to_s.should == "ask_tablets_not_brought_to_clinic: true"
  end
  
end
