require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RelationshipController do
  fixtures :patient, :encounter, :concept, :location,:patient_identifier,:person,:relationship_type,
  :concept_datatype, :concept_class, :order_type, :concept_set, :patient_identifier_type, :relationship

  before(:each) do
    login_current_user  
  end  
 
  it "should create a relationship" do
    post :create, :relationship=> {"person_id"=>person(:andreas).id,"relationship"=>relationship_type(:relationship_type_00004).id,"relative_id"=>patient(:pete).id}
    response.should redirect_to(:action => 'list')    
  end
  
  it "should update a relationship" do
    post :update, :id => relationship(:andreas).id, :relationship=> {"relationship"=>relationship_type(:relationship_type_00004).id}
    response.should redirect_to(:action => 'list')    
  end
  
  it "should create a new relationship" do
   get :new
   response.should be_success
  end


end
