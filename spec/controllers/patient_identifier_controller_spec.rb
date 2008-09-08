require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PatientIdentifierController do
  fixtures :patient, :encounter, :concept, :location,:patient_identifier,
  :concept_datatype, :concept_class, :order_type, :concept_set

  before(:each) do
    login_current_user  
  end  
 
  it "should get next available arv id" do
    get :next_available_arv_id
    response.should be_success
  end
  
  it "should get patients' national id" do
    post :national_id, :identifier => "SAL 158"
    response.should be_success
  end
  
  it "should get patients' filing number" do
    post :filing_number, :identifier => "SAL 158"
    response.should be_success
  end

  it "should get all patients' identifers" do
    post :get_all, :identifier => "SAL 158"
    response.should be_success
  end

end
