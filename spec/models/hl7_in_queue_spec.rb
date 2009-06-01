require File.dirname(__FILE__) + '/../spec_helper'

describe Hl7InQueue do

  sample({
    :hl7_in_queue_id => 1,
    :hl7_source => 1,
    :hl7_source_key => '',
    :hl7_data => 'aaa',
    :state => 1,
    :date_processed => Time.now,
    :error_msg => 'bbb',
    :date_created => Time.now,
  })

  it "should be valid" do
    hl7_in_queue = create_sample(Hl7InQueue)
    hl7_in_queue.should be_valid
  end
  
end
