require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LocationController do

  before do
    login_current_user
    @location = location(:chinthembwe_health_centre)
  end

  it "should display a list of location" do
    get :list
    response.should be_success
    #response.should redirect_to("/location/list")
  end

  it "should display tasks for current room" do
    property = GlobalProperty.new(:property => 'rooms_to_tasks',
                                  :property_value => '"General Reception": "General Reception"')
    property.save
    session[:location] = 'General Reception'
    application_controller = ApplicationController.new
    application_controller.room_tasks('General Reception').should == ['General Reception']

    application_controller.room_tasks('Lounge').should be_nil
  end

  it "should create location" do
    post :create, :location => {"name" =>"Angoni", "description" => "LL near old airport"}
    response.should redirect_to("/location/list")
  end

  it "should edit location" do
    post :edit, :id => @location.id
    response.should be_success
  end

  it "should update location" do
    post :update, :id => @location.id, :location => {"description" => "LL near old airport"}
    response.should redirect_to("/location/list")
  end

end
