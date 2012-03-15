require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DrugOrderController do
  fixtures :patient, :encounter, :concept, :location, :drug, :drug_barcodes,
  :concept_datatype, :concept_class, :order_type, :concept_set

  before(:each) do
    login_current_user  
    session[:patient_id] = patient(:andreas).id
    session[:encounter_datetime] = Time.now()
  end  
 
  it "should dispense" do
    get :dispense
    response.should be_success
  end
  
  it "should give out recommended prescription" do
    get :recommended_prescription , :regimen => "Zidovudine Lamivudine Nevirapine"
    response.should be_success
  end

  it "should create a prescription" do
    post :create
    response.should redirect_to("/patient/menu")
  end

  it "should display prescribed dosages" do
  end

end
