require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserrolesController do
  fixtures :patient, :encounter, :concept, :location, :users,:user_role,
  :concept_datatype, :concept_class, :order_type, :concept_set, :role

  before(:each) do
    login_current_user  
  end  
  
  it "should assign a role to a user" do
    post :create ,:role=>{"role"=>"Therapeutic Feeding Clerk","description"=>"Gives plumpy nut based on BMI"}
    response.should redirect_to("/userroles/list")
  end
 
    #response.should be_success
      
end
