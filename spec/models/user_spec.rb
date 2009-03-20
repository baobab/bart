require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  sample({
    :username => "xmikmck",
    :salt => "laWkLAw6QB",
    :password => "904bf83b60c821aacc43d601b203b124a63fa08f", # mike
    :date_created => "2007-10-17 15:01:53 +02:00".to_time,
    :date_changed => "2007-10-17 15:01:53 +02:00".to_time,
    :first_name => "Mike",
    :middle_name => "Vonderohe",
    :last_name => "McKay",
    :date_voided => nil,
    :voided => false,
    :void_reason => nil,
    :voided_by => nil,
    :creator => 1,
    :changed_by => 1,
    :secret_question => nil,
    :secret_answer => nil,
    :system_id => "Baobab Admin",
  })

  it "should be valid" do
    user = create_sample(User)
    user.should be_valid
  end

  it "should have a role" do
    users(:mikmck).has_role("superuser").should == true
  end

  it "should have a name" do
    users(:mikmck).name.should == 'Mike McKay'
  end

  it "should find privileges by name" do
    users(:mikmck).has_privilege_by_name("Enter past visit").should be_true
  end

  it "should indicate if the user has a specified privilege" do
    users(:mikmck).has_privilege(privilege(:enter_past_visit)).should be_true
    users(:mikmck).has_privilege(privilege(:tb_reception)).should be_false
  end

  describe "#activities" do
    before do
      @user = User.new
      @tb_program = stub_model(Program, :name => "Tuberculosis (TB)")
      @hiv_program = stub_model(Program, :name => "HIV")
      Program.stub!(:find_by_name).with("HIV").and_return(@hiv_program)
      Program.stub!(:find_by_name).with(@tb_program.name).and_return(@tb_program)
    end

    it "should list activities" do
      @user.activities.should == []
    end

    it "is in the HIV program by default" do
      @user.activities.should == []
      @user.current_programs.should == [@hiv_program]
    end

    it "is in the TB program if activities include TB-related" do
      @user.stub!(:activities).and_return(["TB"])
      @user.current_programs.should include(@tb_program)
    end

    it "is not in the TB program if disable_@tb_program property == true" do
      GlobalProperty.stub!(:find_by_property).and_return(stub_model(GlobalProperty, :property_value => 'true'))
      @user.stub!(:activities).and_return(["TB"])
      @user.current_programs.should_not include(@tb_program)
    end

    it "has no programs if activities are limited to General Reception" do
      @user.stub!(:activities).and_return(["General Reception"])
      @user.current_programs.should be_empty
    end
  end

  it "should list privileges" do
    users(:mikmck).privileges.should == [Privilege.find_by_privilege('Enter past visit')]
    User.new.privileges.should be_empty
  end

  it "should encrypt password with salt before creating" do
    user = User.new(:username => 'test', :password => 'tset')
    user.save
    user.password.should_not == 'tset'
    user.salt.length.should == 10
  end

  it "should encrypt password using SHA1" do
    user = users(:mikmck)
    (user.password =~ /[g-z]/).should == nil
    user.password.length.should == 40
  end

  it "should reset password class variable after creating" do
    user = User.new(:username => 'test', :password => 'tset')
    user.save
    user.instance_variable_get('@password').should be_nil
  end

  it "should authenticate given a userame and password" do
    user = users(:mikmck)
    User.authenticate('mikmck', 'mike').should == user
    User.authenticate('mikmck', 'xxx').should == nil
  end

  it "should login" do
    user = users(:mikmck)
    user.try_to_login.should == nil
  end

  it "should generate a random string of a given length" do
    text = User.random_string(3)
    text.class.should == String
    text.length.should == 3
  end

  it "should assign roles" do
    user = User.new(:username => 'test2', :password => 'tset')
    user.save
    user.roles.should be_empty
    role = Role.find_by_role('Registration Clerk')
    user.assign_role(Role.find_by_role('Registration Clerk'))
    user.reload
    user.roles.should == [role]
  end

end
