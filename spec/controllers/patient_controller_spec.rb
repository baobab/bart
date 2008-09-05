require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PatientController do
# fixtures :concept_set, :concept
  fixtures :patient, :encounter, :orders, :drug_order, :drug, :concept, 
  :concept_datatype, :concept_class, :order_type, :concept_set, :location

  before(:each) do
    login_current_user  
    @patient = patient(:andreas)
    session[:patient_id] = @patient.id
    session[:encounter_datetime] = Time.now()
  end  
 
  it "should create arv number" do
    post :create_arv_number, :arv_number => "8"
    response.should redirect_to("/patient/menu")
  end

  it "should create filing number" do
    post :create_filing_number
    response.should redirect_to("/patient/menu")
  end

  it "should create new filing number" do
    patient(:pete).set_national_id
    post :set_new_filing_number, :barcode => patient(:pete).national_id
    #response.should redirect_to("/patient/set_new_filing_number/?barcode=#{patient(:pete).national_id}")
    response.should be_success
  end

  it "should display patient detail summary" do
    get :patient_detail_summary
    response.should be_success
  end

  it "should display patient encounters according to date" do
    get :encounters
    response.should be_success
  end

  it "should update patients' outcome" do
    post :update_outcome, :patient_day => Time.now.day ,:patient_month => Time.now.month,:patient_year => Time.now.year,:outcome => "Died" ,:location => location(:unknown).name, :location_id => location(:unknown).id
    response.should be_success
  end

  it "should create a new patient record" do
    post :create, :patient_year => Time.now.year ,:patient_month => Time.now.month,:patient_day => Time.now.day, :city_village => "Lilongwe", :current_ta =>{"identifier"=>"Amidu"}, :other_name => {"identifier"=>""}, :occupation => "Other", :p_address => {"identifier"=>"market"}, :patient_age => "", :age_estimate => 0, :patient_name =>{"given_name"=>"Agness","family_name"=>"James"}, :cell_phone =>{"identifier" => "Unknown"},:home_phone =>{"identifier" => "Unknown"}, :office_phone => {"identifier"=>"Unknown"}, :patient =>{"birthplace"=>"Area 10","gender"=>"Female"}
    response.should be_success
  end

  it "should create patient guardian" #do
    #post :create_guardian, :patient_gender => "Female", :name => "Flo", :family_name => "Land"
    #puts "#{@patient.art_guardian.name rescue 'mwatha'}****"
    #response.should be_success
  #end

end
