require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminController do
 
  it "should alert when date is wrong" do
    get :alert_wrong_date
    response.should be_success
  end

end
  
 
