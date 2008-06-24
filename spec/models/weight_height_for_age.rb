require File.dirname(__FILE__) + '/../spec_helper'

describe WeightHeightForAge do
  fixtures :weight_height_for_ages

  sample({
    :standard_high_weight => 12.3533897399902,
    :standard_low_height => 5.98912000656128,
    :age_in_months => 215,
    :standard_high_height => 5.98821020126343,
    :sex => 'Female',
    :median_weight => 56.6393890380859,
    :age_sex => "2151",
    :standard_low_weight => 7.29257011413574,
    :median_height => 163.65934753418
  })

  it "should be valid" do
    weight_height_for_age = create_sample(WeightHeightForAge)
    weight_height_for_age.should be_valid
  end
  
end
