require File.dirname(__FILE__) + '/../spec_helper'

describe RoleRole do
  # You can move this to spec_helper.rb
  set_fixture_class :role_role => RoleRole
  fixtures :role_role

  sample({
    :parent_role_id => 1,
    :child_role_id => 1,
  })

  it "should be valid" do
    role_role = create_sample(RoleRole)
    role_role.should be_valid
  end
  
end
