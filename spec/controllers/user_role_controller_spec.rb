require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserRoleController do
  fixtures :patient, :encounter, :concept, :location, :users,:user_role,
  :concept_datatype, :concept_class, :order_type, :concept_set, :role

  before(:each) do
    login_current_user  
    @patient = patient(:andreas)
    session[:patient_id] = @patient.id
    session[:encounter_datetime] = Time.now()
  end  
  
  it "should create a user role" do
    post :create ,:role=>{"role"=>role(:role_00005).role_id,"description"=>role(:role_00005).description},:id => @patient.id
    flash[:notice].should eql('Role was successfully created.')
    response.should redirect_to("/user_role/list")
  end

  it "should show a role" do
    post :show, :id => role(:role_00001).id 
    response.should be_success
  end  
      
  it "should create a new role" do
    post :new
    response.should be_success
  end  
      
  it "should edit a role" do
    post :edit, :id => role(:role_00001).id
    response.should be_success
  end  
      
  it "should update a role" do
    post :update, :id => role(:role_00001).id, :role => {"description" => "Baobab developers"}
    response.should redirect_to("/user_role/show/#{role(:role_00001).id}")
  end  
      
  it "should destroy a role" do
    post :destroy, :id => role(:role_00001).id
    response.should redirect_to("/user_role/list")
  end  
      
end
