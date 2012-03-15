require File.dirname(__FILE__) + '/../spec_helper'

describe Tribe do
  # You can move this to spec_helper.rb
  set_fixture_class :tribe => Tribe
  fixtures :tribe

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
