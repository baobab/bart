require File.dirname(__FILE__) + '/../spec_helper'

describe Role do
  # You can move this to spec_helper.rb
  set_fixture_class :role => Role
  fixtures :role

  sample({
    :role_id => 1,
    :role => '',
    :description => '',
  })

  it "should be valid" do
    role = create_sample(Role)
    role.should be_valid
  end
  
end
