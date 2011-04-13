require File.dirname(__FILE__) + '/../spec_helper'

describe Privilege do
  # You can move this to spec_helper.rb
  set_fixture_class :privilege => Privilege
  fixtures :privilege

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
