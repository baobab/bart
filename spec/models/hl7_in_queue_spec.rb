require File.dirname(__FILE__) + '/../spec_helper'

describe Hl7InQueue do
  # You can move this to spec_helper.rb
  set_fixture_class :hl7_in_queue => Hl7InQueue
  fixtures :hl7_in_queue

  sample({
    :hl7_in_queue_id => 1,
    :hl7_source_id => 1,
    :hl7_source_key => '',
    :hl7_data => '',
    :state => 1,
    :date_processed => Time.now,
    :error_msg => '',
    :date_created => Time.now,
  })

  it "should be valid" do
    hl7_in_queue = create_sample(Hl7InQueue)
    hl7_in_queue.should be_valid
  end
  
end
