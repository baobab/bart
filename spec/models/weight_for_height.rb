require File.dirname(__FILE__) + '/../spec_helper'

describe WeightForHeight do
  fixtures :weight_for_heights

  sample({
    :supine_cm => 64,
    :median_weight_height => 120
  })

  it "should be valid" do
    weight_for_height = create_sample(WeightForHeight)
    weight_for_height.should be_valid
  end

  it "should give patient weight for height values" do
    WeightForHeight.patient_weight_for_height_values.should == "{\"16.0\":64.0}"
  end

  it "should round patient's height to its significant amount" do
    WeightForHeight.significant(64).should == 64
    WeightForHeight.significant(64.2).should == 64
    WeightForHeight.significant(64.5).should == 64.5
    WeightForHeight.significant(64.7).should == 64.5
    WeightForHeight.significant(64.9).should == 64.5
  end
  
end
