require File.dirname(__FILE__) + '/../test_helper'

class PatientIdentifierTest < Test::Unit::TestCase
  # You can move this to test_helper.rb
  set_fixture_class :patient_identifiers => PatientIdentifier
  fixtures :patient_identifier, :users, :location

  cattr_reader :patient_identifier_default_values
  @@patient_identifier_default_values = {
    :patient_id => 0,
    :identifier => '',
    :identifier_type => 0,
    :preferred => 0,
    :location_id => 0,
    :creator => 0,
    :date_created => '2000-01-01 00:00:00',
    :voided => false,
    :voided_by => 0,
    :date_voided => '2000-01-01 00:00:00',
    :void_reason => '',
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
    patient_identifier = create
    assert patient_identifier.valid?, "Patient identifier was invalid:\n#{patient_identifier.to_yaml}"
  end

	def test_should_update_identifier
    patient_identifier = create
    assert PatientIdentifier.update(1, 'MPC 99', 18, 'Testing first update')
    assert PatientIdentifier.update(1, 'MPC 999', 18, 'Testing second update')
    assert_nil PatientIdentifier.update(1, 'MPC 99', 18, 'Testing first update')
	end

private

  def create(options={})
    PatientIdentifier.create(patient_identifier_default_values.merge(options))
  end

end
