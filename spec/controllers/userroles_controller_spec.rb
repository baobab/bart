require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserrolesController do
  fixtures :patient, :encounter, :concept, :location, :users,:user_role,
  :concept_datatype, :concept_class, :order_type, :concept_set, :role

  before(:each) do
    login_current_user  
  end  
  
  it "should assign a role to a user" do
    post :create ,:role=>{"role"=>"Therapeutic Feeding Clerk","description"=>"Gives plumpy nut based on BMI"}
    flash[:notice].should be_eql('Role was successfully created.')
    response.should redirect_to("/userroles/list")
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
    response.should redirect_to("/userroles/show/#{role(:role_00001).id}")
  end  
      
  it "should destroy a role" do
    post :destroy, :id => role(:role_00001).id
    response.should redirect_to("/userroles/list")
  end  

end
