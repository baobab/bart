require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EncounterController do
  fixtures :patient, :encounter, :concept, :location,:patient_identifier,
  :concept_datatype, :concept_class, :order_type, :concept_set, :encounter_type

  before(:each) do
    login_current_user  
    @patient = patient(:andreas)
    session[:patient_id] = @patient.id
  end  

  it "should display a summary of encounter type" do
    post :summary, :id => encounter(:andreas_art_visit).id
    response.should be_success
  end
   
  it "should find a patient by a barcode scan" do
    post :scan, :barcode => @patient.national_id
    response.should redirect_to("/patient/set_patient/#{@patient.id}")
  end

  it "should create an encounter" do
    post :create, :form_id=>"55",:observation =>{"select:398"=>"3","select:399"=>"3"},
                  :encounter_type_id => encounter_type(:hiv_reception).id
    response.should redirect_to("/patient/menu?")
  end

end
