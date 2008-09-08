require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LocationController do
  fixtures :patient, :encounter, :concept, :location,
  :concept_datatype, :concept_class, :order_type, :concept_set

  before(:each) do
    login_current_user  
  end  
 
  it "should display a list of location" do
    get :list
    response.should be_success
    #response.should redirect_to("/location/list")
  end
  
end
