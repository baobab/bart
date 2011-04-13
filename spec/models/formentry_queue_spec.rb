require File.dirname(__FILE__) + '/../spec_helper'

describe FormentryQueue do
  # You can move this to spec_helper.rb
  set_fixture_class :formentry_queue => FormentryQueue
  fixtures :formentry_queue

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
