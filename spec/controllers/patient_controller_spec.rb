require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PatientController do
# fixtures :concept_set, :concept, :patient_identifier, :patient_identifier_type,
  fixtures :patient, :encounter, :orders, :drug_order, :drug, :concept,:encounter_type,
  :concept_datatype, :concept_class, :order_type, :concept_set, :location, :patient_name,:program

  before(:each) do
    login_current_user  
    @patient = patient(:andreas)
    session[:patient_id] = @patient.id
    session[:encounter_datetime] = Time.now()
    session[:outcome] = @patient.outcome
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
    flash[:notice].should be_eql('Created new filing number')
    response.should be_success
  end

  it "should display patient detail summary" do
    get :summary
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

  it "should set a new patient record" do
    post :new
    response.should be_success
  end

  it "should create a new patient record" do
    post :create, :patient_year => Time.now.year ,:patient_month => Time.now.month,:patient_day => Time.now.day, :city_village => "Lilongwe", :current_ta =>{"identifier"=>"Amidu"}, :other_name => {"identifier"=>""}, :occupation => "Other", :p_address => {"identifier"=>"market"}, :patient_age => "", :age_estimate => 0, :patient_name =>{"given_name"=>"Agness","family_name"=>"James"}, :cell_phone =>{"identifier" => "Unknown"},:home_phone =>{"identifier" => "Unknown"}, :office_phone => {"identifier"=>"Unknown"}, :patient =>{"birthplace"=>"Area 10","gender"=>"Female"}
    flash[:info].should be_eql('Patient was successfully created.')
    response.should be_success
  end

  it "should create patient guardian" do
    post :create_guardian, :patient_gender => "Female", :name => "Flo", :family_name => "Land"
    response.should be_success
  end

  it "should display hl7 report" do
    post :hl7, :id => patient(:andreas).id
    response.should be_success
  end

  it "should list patients by visit date" do
    post :list_by_visit_date, :id => "2008-09-01"
    response.should be_success
  end

  it "should set and show encounters" do
    post :set_and_show_encounters, :id => patient(:pete).id
    response.should redirect_to("/patient/encounters")
  end

  it "should edit a patient record" do
    post :edit,:id => patient(:pete).id
    response.should be_success
    post :update, :id => patient(:pete).id,:patient_year => Time.now.year ,:patient_month => Time.now.month,:patient_day => Time.now.day, :city_village => "Lilongwe", :current_ta =>{"identifier"=>"Amidu"}, :other_name => {"identifier"=>""}, :occupation => "Other", :p_address => {"identifier"=>"market"}, :patient_age => "", :age_estimate => 0, :patient_name =>{"given_name"=>"Agness","family_name"=>"James"}, :cell_phone =>{"identifier" => "Unknown"},:home_phone =>{"identifier" => "Unknown"}, :office_phone => {"identifier"=>"Unknown"}, :patient =>{"birthplace"=>"Area 10","gender"=>"Female"}
    response.should redirect_to("/patient/list")
  end

  it "should set datetime for retrospective data entry" do
    post :set_datetime_for_retrospective_data_entry, :retrospective_patient_day => "12" ,:retrospective_patient_month => "9" ,:retrospective_patient_year => "2002"    
    response.should redirect_to("/patient/menu")
  end

  it "should display patients' mastercard" do
    post :mastercard, :patient_id => @patient.id
    response.should be_success
  end

  it "should resert patients' sessions" do
    get :change
    response.should redirect_to("/patient/menu")
  end

  it "should set encounter not to be retrospective" do
    get :not_retrospective_data_entry
    response.should redirect_to("/patient/menu")
  end

  it "should display main menu via index" do
    get :index
    response.should redirect_to("/patient/menu")
  end

  it "should display main menu" do
    get :menu
    response.should be_success
  end

  it "should display search results" do
    post :search_results, :last =>"Banda", :first =>"Mary", :sex =>"Female"
    response.should be_success
  end

  it "should set date" do
    post :set_date, :patient_day =>"Unknown", :patient_month =>"Unknown", :patient_year =>"Unknown", :patient_age => "30"
    response.should be_success
  end

  it "should print a message" do
    patient_controller = PatientController.new
    new_patient = @patient
    old_patient = patient(:pete)
    old_patient.set_filing_number
    expected_text = patient_controller.printing_message(new_patient,old_patient)
    expected_text.should == "<div id='patients_info_div'>\n     <table>\n       <tr><td class='filing_instraction'>Filing actions required</td><td class='filing_instraction'>Name</td><td>Old Label</td><td>New label</td></tr>\n       <tr><td>Move Active → Dormant</td><td class='filing_instraction'>Pete Puma</td><td  class='old_label'><p class=active_heading>MPC Active</p><b></b></td><td  class='new_label'><p class=dormant_heading>MPC Dormant</p><b>0 00 01</b></td></tr>  \n      <tr><td>Move Dormant → Active</td><td class='filing_instraction'>Andreas Jahn</td><td  class='old_label'><p class=dormant_heading>MPC Dormant</p><b>0 00 01</b></td><td  class='new_label'><p class=active_heading>MPC Active</p><b>0 00 01</b></td></tr>\n       <tr><td></td><td></td><td><button class='page_button' onmousedown='print_filing_numbers();'>Print</button></td><td><button  class='page_button' onmousedown='next_page();'>Done</button></td></tr>\n     </table>"
  end

  it "should set patient" do
    post :set_patient, :id => @patient.national_id
    response.should redirect_to("/patient/summary")
  end

  it "should set guardian" do
    post :set_guardian, :id => patient(:pete).national_id
    response.should redirect_to("/patient/menu")
  end

  it "should add a program" do
    post :add_program, :id => patient(:pete).national_id, :program_id => program(:program_00002).id
    response.should redirect_to("/patient/menu")
  end

  it "should set patient" do
    post :set_patient, :id => patient(:pete).national_id
    response.should redirect_to("/patient/add_program")
  end

  it "should archive patients" do
    post :archive_patients, :id => patient(:pete).id
    response.should redirect_to("/patient/summary")
  end

  it "should reassign patient filing number" do
    post :reassign_patient_filing_number, :id => patient(:pete).id
    response.should be_success
  end

  it "should search by naional id" do
    post :patient_search_results, :id => @patient.national_id
    response.should redirect_to("/patient/menu")
  end

  it "should search by names" do
    get :patient_search_names
    response.should be_success
  end

  it "should search by name" do
    puts @patient.birthdate.strftime("%Y")
    puts @patient.birthdate.strftime("%m")
    puts @patient.birthdate.strftime("%d")
    post :search_by_name,:national_id => @patient.national_id,:family_name => @patient.last_name,
         :name => @patient.first_name,:patient_birth_year => @patient.birthdate.strftime("%Y"),
         :patient_birth_month => @patient.birthdate.strftime("%m"),:patient_birth_date => @patient.birthdate.strftime("%d")
    response.should redirect_to("/patient/menu")
  end

  it "should check national id validity" do
    patient_controller = PatientController.new
    expected_text = patient_controller.chk_national_id_validity(@patient.national_id)
    expected_text.should == "patient not found"
  end  

  it "should print filing numbers" do
    get :print_filing_numbers
    response.should be_success
  end

  it "should validate weight height" do
    get :validate_weight_height
    response.should be_success
  end

  it "should modify mastercard"

=begin
  it "should show initial patients registered at clinic" do
    post :initial_patients_registered_at_clinic, :ending_year => Date.today.strftime("%Y") ,:ending_month => Date.today.strftime("%b") ,
          :ending_date => Date.today.strftime("%d") , :patient_type => "Female"
    response.should be_success
  end
=end

  it "should show registered patient at clinic" do
    post :registered_at_clinic, :ending_year => Date.today.strftime("%Y") ,:ending_month => Date.today.strftime("%b") ,
         :starting_year => Date.today.strftime("%Y") ,:starting_month => Date.today.strftime("%b"),
         :starting_date => Date.today.strftime("%d"),:ending_date => Date.today.strftime("%d") , :gender => "Female"
    response.should be_success
  end

  it "should show return visits" do
    post :return_visits, :ending_year => Date.today.strftime("%Y") ,:ending_month => Date.today.strftime("%b") ,
         :starting_year => Date.today.strftime("%Y") ,:starting_month => Date.today.strftime("%b"),
         :starting_date => Date.today.strftime("%d"),:ending_date => Date.today.strftime("%d") , :gender => "Female"
    response.should be_success
  end

  it "should set transfer location"
  it "should show lab results"
  it "should show lab menu"
  it "should show detail lab results"
  it "should show detail lab results graph"
  
  it "should show admin menu" do
    get :admin_menu
    response.should be_success
  end  

=begin
  it "should show vitals in detail" do
    post :vitals_in_detail, :ending_year => Date.today.strftime("%Y") ,:ending_month => Date.today.strftime("%b") ,
          :ending_date => Date.today.strftime("%d") , :patient_type => "Female"
    response.should be_success
  end
=end

  it "should show total number of patients" do
    post :total_number_of_patients, :ending_year => Date.today.strftime("%Y") ,:ending_month => Date.today.strftime("%b") ,
          :ending_date => Date.today.strftime("%d") , :patient_type => "Female"
    response.should be_success
  end

  it "should find by arv number" do
    post :find_by_arv_number, :arv_number => @patient.arv_number
    response.should be_success
  end

end
