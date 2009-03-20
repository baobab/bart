require File.dirname(__FILE__) + '/../spec_helper'

describe OrderType do

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
  
  it "should find by name" do
    order_type(:order_type_00001).should == OrderType.find_by_name("Give drugs")
  end  

end
