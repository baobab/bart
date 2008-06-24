require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  fixtures :users

  sample({
    :username => "mikmck",
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
  
end
