require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  fixtures :users, :privilege, :role, :role_privilege, :user_role, :program

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

  it "should list activities" do
    User.new.activities.should == []
    users(:mikmck).activities.should == []
  end

  it "should set activities" do
    user = users(:mikmck)
    user.activities = ['View reports', 'Enter past visit']
    user.reload
    user.activities.should == ['View reports', 'Enter past visit']
  end

  it "should list current programs" do
    User.new.current_programs.should == [program(:hiv)]
    users(:mikmck).current_programs.should == [program(:hiv)]
  end

  it "should list privileges" do
    users(:mikmck).privileges.should == [Privilege.find_by_privilege('Enter past visit')]
    User.new.privileges.should have(:no).records
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

  it "should reset password class variable after creating"

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
    user.roles.should have(:no).records
    role = Role.find_by_role('Registration Clerk')
    user.assign_role(Role.find_by_role('Registration Clerk'))
    user.reload
    user.roles.should == [role]
  end

end
