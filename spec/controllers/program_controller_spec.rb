require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ProgramController do
  fixtures :patient, :encounter, :concept, :location,:patient_identifier,:person,:relationship_type,
  :concept, :concept_class, :order_type, :concept_set, :patient_identifier_type, :program

  before(:each) do
    login_current_user  
  end  
 
  it "should create a new patient program" do
    post :create, :program=> {"concept_id"=>concept(:cough).id}
    response.should redirect_to(:action => 'list')    
  end
  

end
