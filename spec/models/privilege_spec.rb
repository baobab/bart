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

  it "should create privileges and attach to roles" do
    expect = "HIV First visit", "ART Visit", "Give drugs", "Date of ART initiation", "HIV Staging", "HIV Reception", "Height/Weight", "Update outcome", "TB Reception", "Move file from dormant to active", "Enter past visit", "View reports"
    Privilege.create_privileges_and_attach_to_roles.should == expect
  end  
  
end
