require "#{File.dirname(__FILE__)}/../test_helper"

class UpdateGuardianTest < ActionController::IntegrationTest
  fixtures :users, :global_property, :privilege, :program, :location
  fixtures :patient, :patient_name, :patient_identifier, :patient_identifier_type, :patient_program
  fixtures :encounter, :encounter_type, :concept, :obs, :drug_order, :drug
  # order?
  
  def test_should_find_patient_and_update_guardian
    patient = patient(:andreas)
    login
    select_tasks ['HIV Reception']
    scan_patient patient_identifier(:andreas_national_id).identifier, patient.patient_id
    assert_equal session[:patient_id], patient.patient_id

    # Check the menu
    get "/patient/menu?no_auto_load_forms=true"
    assert_response :success
  
    # Check the mastercard
    get "/patient/mastercard/#{patient.id}"
    assert_response :success
    assert_tag :td, :content => "Andreas Jahn"
    
    # Update the guardian
    # ????
  end
    
end
