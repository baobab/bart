require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EncounterTypeController do

  before do
    login_current_user
    @patient = patient(:andreas)
    session[:patient_id] = @patient.id
  end

  it "should update params filter" do
    post :update_params_filter
    response.should be_success
  end

  it "should initialize a new encounter type" do
    get :new
    response.should be_success
  end

  it "should create encounter type" do
    post :create, :encounter_type => {"name" => "Move file from dormant to active","description" =>"","creator" => User.current_user.id,"date_created" => Time.now}
    response.should redirect_to("/encounter_type/list")
  end

  it "should update encounter type" do
    post :update, :id => encounter_type(:hiv_first_visit).id, :encounter_type => {"name" => "description"}
    response.should redirect_to("/encounter_type/list")
  end

  it "should destroy encounter type" do
    post :destroy, :id => encounter_type(:hiv_first_visit).id
    response.should redirect_to("/encounter_type/list")
  end

  it "should cancel an encounter type" do
    get :cancel
    response.should redirect_to("/encounter_type/list")
  end


end
