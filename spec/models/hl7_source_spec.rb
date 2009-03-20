require File.dirname(__FILE__) + '/../spec_helper'

describe Hl7Source do

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
