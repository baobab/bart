require File.dirname(__FILE__) + '/../spec_helper'

describe Order do
  fixtures :order

  sample({
    :order_type_id => 1,
    :encounter_id => 3,
    :creator => 1,
    :date_created => "2007-03-05 00:00:00".to_time,
    :voided => false,
  })

  it "should be valid" do
    order = create_sample(Order)
    order.should be_valid
  end
  
end
