require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PatientIdentifierController do
  fixtures :patient, :encounter, :concept, :location,:patient_identifier,
  :concept_datatype, :concept_class, :order_type, :concept_set

  before(:each) do
    login_current_user  
  end  
 
  it "should find identifers" do
    get :find
    response.should be_success
  end

  it "should get next available arv id" do
    get :next_available_arv_id
    response.should be_success
    response.should have_text("  arv_number_field = $('arv_number'); \n  if(arv_number_field.value == ''){\n    $('tt_page_new_arv_number').getElementsByTagName(\"input\")[0].value='1'\n  }\n")
  end
  
  it "should get patients' national id" do
    post :national_id, :identifier => "SAL 158"
    response.should be_success
    response.should have_text("P170000000013")
  end
  
  it "should get patients' filing number" do
    post :filing_number, :identifier => "SAL 158"
    response.should be_success
    response.should have_text("FN10100001")
  end

  it "should get all patients' identifers" do
    post :get_all, :identifier => "SAL 158"
    response.should be_success
    response.should have_text("FN10100001<br/>Health Care Worker<br/>P170000000013<br/>SAL 158<br/>")
  end

end
