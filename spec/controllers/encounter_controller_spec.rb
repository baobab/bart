require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EncounterController do

  before do
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

  it "should create an encounter for an ART visit" do
    post :create, :form_id=>"55",:observation =>{"select:398"=>"3","select:399"=>"3"},
                  :encounter_type_id => encounter_type(:art_visit).id
    response.should redirect_to("/patient/menu?")
  end

  it "should get arv national id" do
    encounter_controller = EncounterController.new()
    encounter_controller.get_arv_national_id.should == "TMP100"
  end

  it "should determine hiv wasting syndrome" do
    encounter_controller = EncounterController.new()
    encounter_controller.determine_hiv_wasting_syndrome(encounter(:andreas_art_visit)).should == true
  end

  it "should view an encounter" do
    post :view, :id => encounter(:andreas_art_visit).id
    response.should be_success
  end

  it "should void an encounter" do
    post :void, :id => encounter(:andreas_art_visit).id, :void => {"reason" => "wrong values"}
    response.should redirect_to("/patient/encounters")
  end

end
