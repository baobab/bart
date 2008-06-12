require File.dirname(__FILE__) + '/../test_helper'

class RetrospectiveOccupationTest < Test::Unit::TestCase
  # You can move this to test_helper.rb
  set_fixture_class :patient_identifiers => PatientIdentifier
  fixtures :patient_identifier, :users, :location
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
    ro = RetrospectiveOccupation.new
    ro.ask_arv_range(157, 158)
    assert_equal ['SAL 157', 'SAL 158'], ro.arv_range
  end
  
  def test_should_find_patient_ids_in_range
    ro = RetrospectiveOccupation.new
    ro.arv_range = ['SAL 157', 'SAL 158']
    ro.find_arv_patients_ids
    assert_equal [1, 2], ro.arv_patient_ids
  end

  def test_should_find_patients
    ro = RetrospectiveOccupation.new
    ro.arv_range = ['SAL 157', 'SAL 158']
    ro.find_arv_patients_ids
    ro.find_arv_patients
    assert_equal [2, 1], ro.arv_patients.map(&:id)
  end

  def test_should_update_patient_occupations
    ro = RetrospectiveOccupation.new
    ro.arv_range = ['SAL 157']
    ro.find_arv_patients_ids
    ro.find_arv_patients
    ro.update_occupations()
    assert_equal 'Farmer', Patient.find(2).occupation
  end
=end  
end
