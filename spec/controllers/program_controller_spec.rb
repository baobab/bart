require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ProgramController do

  before do
    login_current_user
  end

  it "should prepare a new patient program to be created" do
    get :new
    response.should be_success
  end

  it "should prepare a new patient program to be edited" do
    post :edit,:id => program(:hiv).id
    response.should be_success
  end

  it "should create a new patient program" do
    post :create, :program=> {"concept_id"=>concept(:cough).id}
    response.should redirect_to(:action => 'list')
  end

  it "should update patient program" do
    post :update, :id =>concept(:cough).id ,:program=> {"name"=>"concept_name"}
    response.should be_success
  end

  it "should destroy a patient program" do
    post :create, :program=> {"concept_id"=>concept(:cough).id}
    response.should redirect_to(:action => 'list')
    post :destroy, :id => concept(:cough).id
    response.should be_success
  end
end
