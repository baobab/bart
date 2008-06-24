require File.dirname(__FILE__) + '/../spec_helper'

describe OrderType do
  fixtures :order_type

  sample({
    :name => "Give drugs",
    :date_created => "2007-04-17 11:05:41 +02:00".to_time,
    :creator => 8,
    :description => "",
    :order_type_id => 1,
  })

  it "should be valid" do
    order_type = create_sample(OrderType)
    order_type.should be_valid
  end
  
end
