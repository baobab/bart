require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PatientIdentifierTypeController do
  fixtures :patient, :encounter, :concept, :location,:patient_identifier,
  :concept_datatype, :concept_class, :order_type, :concept_set, :patient_identifier_type

  before(:each) do
    login_current_user  
  end  
 
  it "should list identifier types" #do
    #get :list
    #response.should be_success
    #response.should redirect_to("/list")
  #end

  it "should be ready to create a new identifier type" do
    get :new
    response.should be_success
  end

  it "should create new identifier types" do
    post :create
    response.should be_success
  end

end
