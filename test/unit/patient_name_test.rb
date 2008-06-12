require File.dirname(__FILE__) + '/../test_helper'

class PatientNameTest < Test::Unit::TestCase
  # You can move this to test_helper.rb
  set_fixture_class :patient_names => PatientName
  fixtures :patient_name, :users, :location

  cattr_reader :patient_name_default_values
  @@patient_name_default_values = {
    :patient_name_id => 0,
    :preferred => false,
    :patient_id => 0,
    :prefix => '',
    :given_name => '',
    :middle_name => '',
    :family_name_prefix => '',
    :family_name => '',
    :family_name2 => '',
    :family_name_suffix => '',
    :degree => '',
    :creator => 0,
    :date_created => '2000-01-01 00:00:00',
    :voided => false,
    :voided_by => 0,
    :date_voided => '2000-01-01 00:00:00',
    :void_reason => '',
    :changed_by => 0,
    :date_changed => '2000-01-01 00:00:00',
  }

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

  def test_should_create_record
    patient_name = create
    assert patient_name.valid?, "Patient name was invalid:\n#{patient_name.to_yaml}"
  end

private

  def create(options={})
    PatientName.create(patient_name_default_values.merge(options))
  end

end
