require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GlobalPropertyController do

  before do
    login_current_user
  end

  it "GET index redirects to list" do
    get :index
    response.should redirect_to("/global_property/list")
  end

  it "GET new responds successfully" do
    get :new
    response.should be_success
  end

  it "POST create redirects to list" do
    post :create, :global_property => {"property" => "label_width_height","property_value" => "806,329"}
    response.should redirect_to("/global_property/list")
  end

end
