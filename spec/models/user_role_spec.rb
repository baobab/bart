require File.dirname(__FILE__) + '/../spec_helper'

describe UserRole do
  sample({
    :user_id => 10,
    :role_id => 10,
  })

  it "should be valid" do
    user_role = create_sample(UserRole)
    user_role.should be_valid
  end
  
end
