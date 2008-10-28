require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GlobalPropertyController do
  fixtures :location,:global_property,:patient,:users

  before(:each) do
    login_current_user  
  end  
 
  it "should display a list of location" do
    get :index
    response.should redirect_to("/global_property/list")
  end
  
  it "should create a new global property" do
    get :new
    response.should be_success
  end
  
  it "should create a global property" do
    post :create, :global_property => {"property" => "label_width_height","property_value" => "806,329"}
    response.should be_success
  end
  
end
