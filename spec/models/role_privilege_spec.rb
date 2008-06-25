require File.dirname(__FILE__) + '/../spec_helper'

describe RolePrivilege do
  # You can move this to spec_helper.rb
  set_fixture_class :role_privilege => RolePrivilege
  fixtures :role_privilege

  sample({
    :role_id => 1,
    :privilege_id => 1,
  })

  it "should be valid" do
    role_privilege = create_sample(RolePrivilege)
    role_privilege.should be_valid
  end
  
end
