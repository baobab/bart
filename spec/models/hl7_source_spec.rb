require File.dirname(__FILE__) + '/../spec_helper'

describe Hl7Source do
  # You can move this to spec_helper.rb
  set_fixture_class :hl7_source => Hl7Source
  fixtures :hl7_source

  sample({
    :hl7_source_id => 1,
    :name => 'Address',
    :description => '',
    :creator => 1,
    :date_created => Time.now,
  })

  it "should be valid" do
    hl7_source = create_sample(Hl7Source)
    hl7_source.should be_valid
  end
  
end
