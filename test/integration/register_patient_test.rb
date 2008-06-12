require "#{File.dirname(__FILE__)}/../test_helper"

class RegisterPatientTest < ActionController::IntegrationTest
  fixtures :users, :global_property, :privilege, :program, :location
  fixtures :patient, :patient_name, :patient_identifier, :patient_identifier_type, :patient_program
  fixtures :encounter, :encounter_type, :concept, :obs, :drug_order, :drug
  # order?

  def test_should_log_in_and_select_tasks
    login
    select_tasks            
  end
  
  def test_should_find_or_register_unknown_patient
    login
    select_tasks     
    get "/patient/search?mode=patient"
    assert_template "patient/search"
    post "/patient/search_results", "last"=>"Pepito", "first"=>"Dennis", "sex"=>"Male"
    assert_response :success                                                 
    assert_tag :option, :attributes => {:id => "new_patient"}, :content => "No existing people found for search: ((BR/)) Dennis Pepito Male"
    #TODO assert_tag for the button to say Create Patient
  end  

  def test_should_find_or_register_existing_patient
    login
    select_tasks     
    get "/patient/search?mode=patient"
    assert_template "patient/search"
    post "/patient/search_results", "last"=>"Jahn", "first"=>"Andreas", "sex"=>"Male"
    assert_response :success
    assert_tag :option, :attributes => {:id => "new_patient"}, :content => "Create new  Patient   with details: ((BR/)) Andreas Jahn Male"
  end
    
  def test_should_create_patient
    login
    select_tasks     
    get "/patient/search?mode=patient"
    get "/patient/new", "patient_id"=>"new_patient", "name"=>"Dennis", "family_name"=>"Pepito", "patient_gender"=>"Male"
    assert_response :success     
    post "/patient/create",    
     "occupation"=>"Business", 
     "patient_year"=>"1966", 
     "patient_month"=>"3",
     "patient_day"=>"6", 
     "patient_age"=>{"age_estimate"=>""},
     "patient_id"=>"", 
     "patientaddress"=>{"city_village"=>"Area 12"}, 
     "p_address"=>{"identifier"=>"MBAYANI"}, 
     "current_ta"=>{"identifier"=>"Biwi (A8)"}, 
     "patient_name"=>{"family_name"=>"Pepito", "given_name"=>"Dennis"}, 
     "patient"=>{"birthplace"=>"Area 11", "gender"=>"Male"}, 
     "home_phone"=>{"identifier"=>"Not Available"},
     "cell_phone"=>{"identifier"=>"Not Available"},
     "office_phone"=>{"identifier"=>"Not Available"},
     "age"=>{"identifier"=>""}
    # Ultimately this is redirected by Javascript to the guardian search
    assert_response :success
    
    # Need to setup the session, which should have happened after the redirect
    patient = Patient.find(:first, :order => 'patient_id desc')
    get "/patient/set_patient/#{patient.id}"
    
    # Search for a guardian
    get "/patient/search?mode=guardian" 
    assert_response :success

    # Lookup unknown
    post "/patient/search_results", "last"=>"Pepito", "first"=>"Mary", "sex"=>"Female"
    assert_response :success
    assert_tag :option, :attributes => {:id => "new_patient"}, :content => "No existing people found for search: ((BR/)) Mary Pepito Female"
    #TODO assert_tag for the button to say Create Guardian
            
    # Create guardian    
    get "/patient/create_guardian", "name"=>"Mary", "family_name"=>"Pepito", "patient_gender"=>"Female"
    assert_redirected_to :action => "set_guardian", :id => patient.id + 1

    # Check the menu
    get "/patient/menu?no_auto_load_forms=true"
    assert_redirected_to :action => "set_datetime_for_retrospective_data_entry"

    # Check the mastercard
    get "/patient/mastercard/#{patient.id}"
    assert_response :success
  end
    
end
