require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserController do
  fixtures :patient, :encounter, :concept, :location, :users,
  :concept_datatype, :concept_class, :order_type, :concept_set

  before(:each) do
    @location = location(:lighthouse)
    post :login, :user =>{"username"=>"mikmck","password" =>"mike"} , :location => @location.id
  end  
  
  it "should create a user" do
    post :create ,:user =>{"username"=>"blinding",
    "first_name"=>"Mike",
    "last_name"=>"Banda",
    "password"=>"blinding",
    "middle_name"=>"Bono"},
    "user_confirm"=>{"password"=>"blinding"},
    "user_role"=>{"role_id"=>"Clinician"}
    flash[:notice].should be_eql('User was successfully created.')
    response.should redirect_to("/user/show")
  end
 
  it "should change password" do
    post :change_password, :id => users(:mikmck).id ,:user => {"password"=>"blinding"},"user_confirm"=>{"password"=>"blinding"}
    flash[:notice].should be_eql('Password successfully changed')
    response.should redirect_to("/user/show")
  end
      
  it "should change activities" do
    post :change_activities, :user =>{"activities"=>["HIV Reception","Height/Weight","Update outcome"]}
    response.should redirect_to("/patient/menu")
  end
      
  it "should search a user" do
    post :search_user, :user =>{"username"=>"mikmck"}
    response.should redirect_to("/user/show")
  end
      
  it "should add a user role" do
    post :add_role, :id =>users(:mikmck).id, :user_role =>{"role_id"=>"Registration Clerk"}
    flash[:notice].should be_eql('You have successfuly added the role of Registration Clerk')
    response.should redirect_to("/user/show")
  end
      
  it "should delete a user role" do
    post :add_role, :id =>users(:mikmck).id, :user_role =>{"role_id"=>"Registration Clerk"}
    post :delete_role, :id =>users(:mikmck).id, :user_role =>{"role_id"=>"Registration Clerk"}
    response.should redirect_to("/user/show")
  end
      
  it "should login a user" do
    post :login, :user =>{"username"=>"mikmck","password" =>"mike"} , :location => 'HIV Reception'
    response.should redirect_to("/user/activities")

    property = GlobalProperty.new(:property => 'rooms_to_tasks', 
                                  :property_value => '"General Reception": "General Reception"')
    property.save
    session[:location] = nil
    get :logout
    post :login, :user =>{"username"=>"mikmck","password" =>"mike"} , :location => 'General Reception'
    response.should redirect_to("/patient/menu")
  end
      
  it "should logout a user" do
    get :logout
    response.should redirect_to("/user/login")
  end
      
  it "should show user attributes" do
    post :show 
    response.should be_success
  end
      
end
