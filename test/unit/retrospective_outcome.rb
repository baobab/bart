require File.dirname(__FILE__) + '/../test_helper'

class RetrospectiveOutcomeTest < Test::Unit::TestCase
  # You can move this to test_helper.rb
  set_fixture_class :patient_identifiers => PatientIdentifier
  fixtures :patient_identifier, :patient_identifier_type, :users, :location
  fixtures :encounter_type, :concept
  fixtures :patient

  def setup
    super
    User.current_user = users(:registration)
    Location.current_location = location(:martin_preuss_centre)
  end
  
  def teardown
    super
    User.current_user = nil
    Location.current_location = nil
  end

  def test_truth
    assert true
  end

=begin
  def test_should_ask_range
    ro = RetrospectiveOutcome.new
    ro.ask_arv_range(157, 158)
    assert_equal ['SAL 157', 'SAL 158'], ro.arv_range
  end
  
  def test_should_find_patient_ids_in_range
    ro = RetrospectiveOutcome.new
    ro.arv_range = ['SAL 157', 'SAL 158']
    ro.find_arv_patients_ids
    assert_equal [1, 2], ro.arv_patient_ids
  end

  def test_should_find_patients
    ro = RetrospectiveOutcome.new
    ro.arv_range = ['SAL 157', 'SAL 158']
    ro.find_arv_patients_ids
    ro.find_arv_patients
    assert_equal [2, 1], ro.arv_patients.map(&:id)
  end

  def test_should_update_patient_outcomes
    ro = RetrospectiveOutcome.new
    ro.arv_range = ['SAL 157']
    ro.find_arv_patients_ids
    ro.find_arv_patients
    ro.update_outcomes
    assert_equal 'Stop', Patient.find(2).outcome_status
  end
=end  
end
