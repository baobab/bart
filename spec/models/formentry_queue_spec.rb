require File.dirname(__FILE__) + '/../spec_helper'

describe FormentryQueue do

  sample({
    :formentry_queue_id => 1,
    :form_data => '',
    :status => 1,
    :date_processed => Time.now,
    :error_msg => '',
    :creator => 1,
    :date_created => Time.now,
  })

  it "should be valid" do
    formentry_queue = create_sample(FormentryQueue)
    formentry_queue.should be_valid
  end
  
end
