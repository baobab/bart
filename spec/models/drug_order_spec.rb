require File.dirname(__FILE__) + '/../spec_helper'

describe DrugOrder do
  fixtures :drug_order

  sample({
    :order_id => 1,
    :drug_inventory_id => 5,
    :dose => nil, 
    :units => nil,
    :frequency => nil,
    :prn => false,
    :complex => false,
    :quantity => 60,
  })

  it "should be valid" do
    drug_order = create_sample(DrugOrder)
    drug_order.should be_valid
  end
  
end
