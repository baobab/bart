require File.dirname(__FILE__) + '/../test_helper'
require 'patient_controller'

# Re-raise errors caught by the controller.
class PatientController; def rescue_action(e) raise e end; end

class PatientControllerTest < Test::Unit::TestCase
  fixtures :global_property, :location
  fixtures :users, :user_role, :role, :privilege, :role_privilege
  fixtures :patient
  fixtures :encounter_type
  fixtures :concept

  def setup
    @controller = PatientController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    login
    get :index
    assert_response :redirect
    assert_redirected_to :action => "menu"
  end
  
  def test_should_get_list_by_visit_date
    
  end

  def test_should_use_today_as_default_for_list_by_visit_date
    
  end

  def test_should_use_today_as_default_for_list_by_visit_date_when_bad_date_submitted
    
  end

  
  def test_should_show_patient
  end
  
  def test_should_get_new
  end

  def test_should_get_edit
  end

  def test_should_create_patient
    # post
  end
  
  def test_should_create_guardian  
  end

  def test_should_update_patient
    # post
  end
  
  def test_should_update_pmtct
    # post
  end
  
  def test_should_set_date
  end
  
  def test_should_get_printing_message
    #printing_message
  end
  
  def test_should_get_hl7_for_patient
    #hl7  
  end
  
  def test_should_reset_session_using_change
    #change
  end
  
  def test_should_not_use_retrospective_entry
    #not_retrospective_data_entry
  end
  
  def test_should_set_datetime_for_retrospective_data_entry
  end
  
  def test_should_set_transfer_in
  end
  
  def test_should_find_by_arv_number
  end
  
  def test_should_set_patient
  end
  
  def test_should_set_guardian
  end
  
  def test_should_add_program
  end
  
  def test_should_show_menu
  end
  
  def test_should_archive_patient  
  end
  
  def test_should_reassign_patient_filing_number
  end
  
  def test_should_show_patient_name
  end
  
  def test_should_show_patient_search_results
  end
  
  def test_should_show_search_results
  end
  
  def test_should_show_patient_search_names
  end
  
  def test_should_show_mastercard
  end
  
  def test_should_search_by_name
  end
  
  def test_should_chk_national_id_validity
  end
  
  def test_should_print_filing_numbers
  end
  
  def test_should_validate_weight_height
  end
  
  def test_should_modify_mastercard
  end
  
  def test_should_show_patients_registered_at_clinic
  end
  
  def test_should_show_initial_patients_registered_at_clinic
  end
  
  def test_should_show_return_visits
  end
  
  def test_should_show_total_number_of_patients
  end
  
  def test_should_show_vitals_in_detail
  end
  
  def test_should_show_patient_report_menu
  end  

  def test_should_update_outcome
    # get just returns the view
    # post
    login
    @request.session[:patient_id] = 1
    @request.session[:encounter_datetime] = Date.new
    @request.session[:location_id] = location(:martin_preuss_centre).id
    params = {}
    params[:patient_day] = "Unknown"
    params[:patient_month] = 2
    params[:patient_year] = 2008
    params[:outcome] = "Transfer Out(With Transfer Note)"
    params[:location] = {}
    params[:location][:location_id] = 701
    post :update_outcome, params
    assert_response :success # print and redirect
  end  
    
  def test_should_set_transfer_location
  end
  
  def test_should_create_arv_number
  end
  
  def test_should_show_patient_detail_summary
  end
  
  def test_should_show_paper_mastercard
  end
  
  def test_should_create_filing_number
  end
  
  def test_should_create_paper_mastercard_patients
  end
  
  def test_should_show_encounters
  end
  
end
