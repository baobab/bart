require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ConceptController do
  fixtures :patient, :encounter, :concept, :location, :drug, :drug_barcodes,
  :concept_datatype, :concept_class, :order_type, :concept_set

  before(:each) do
    login_current_user  
    session[:patient_id] = patient(:andreas).id
    session[:encounter_datetime] = Time.now()
  end
  
  it "should initialize a new concept"
  
  it "should edit a concept" 

end
  
     
