require File.dirname(__FILE__) + '/../spec_helper'

describe Privilege do
  sample({
    :privilege_id => 1,
    :privilege => '',
    :description => '',
  })

  it "should be valid" do
    privilege = create_sample(Privilege)
    privilege.should be_valid
  end

end
