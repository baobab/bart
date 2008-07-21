require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ReportsController do
  fixtures :patient


  #Delete this example and add some real ones
  it "should use ReportsController" do
    controller.should be_an_instance_of(ReportsController)
  end

  it "should display the cohort report" do
    login_user :mikmck, :mike, 700
#    select_task 'reports'
    get '/reports/cohort', :id => 'Q2+2008' 
    response.should_not be_redirect
  end

end
