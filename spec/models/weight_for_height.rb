require File.dirname(__FILE__) + '/../spec_helper'

describe WeightForHeight do
  fixtures :weight_for_heights

  sample({
    :supinecm => 64,
    :median_weight_height => 120
  })

  it "should be valid" do
    weight_for_height = create_sample(WeightForHeight)
    weight_for_height.should be_valid
  end
  
end
