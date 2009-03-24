require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ObservationController do

  before do
    login_current_user
    @obs = Observation.find(:first)
  end

  it "should get concept" do
    get :concept, :name => concept(:arv_first_line_regimen).name
    response.should be_success
  end

  it "should get edit" do
    get :edit, :id => @obs.id
    response.should be_success
  end

  it "should update attributes" do
    put :update, :id => @obs.id, :observation => { :value_text => "something new" }
    response.should be_redirect
    response.should redirect_to("/encounter/summary")
  end

end
