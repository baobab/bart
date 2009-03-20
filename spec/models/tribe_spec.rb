require File.dirname(__FILE__) + '/../spec_helper'

describe Tribe do
  sample({
    :tribe_id => 1,
    :retired => false,
    :name => '',
  })

  it "should be valid" do
    tribe = create_sample(Tribe)
    tribe.should be_valid
  end
  
end
