require File.dirname(__FILE__) + '/../test_helper'

class PatientProgramTest < Test::Unit::TestCase
  # You can move this to test_helper.rb
  set_fixture_class :patient_programs => PatientProgram
  fixtures :patient_program, :users, :location

  cattr_reader :patient_program_default_values
  @@patient_program_default_values = {
    :patient_program_id => 0,
    :patient_id => 0,
    :program_id => 0,
    :date_enrolled => '2000-01-01 00:00:00',
    :date_completed => '2000-01-01 00:00:00',
    :creator => 0,
    :date_created => '2000-01-01 00:00:00',
    :changed_by => 0,
    :date_changed => '2000-01-01 00:00:00',
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
    patient_program = create
    assert patient_program.valid?, "Patient program was invalid:\n#{patient_program.to_yaml}"
  end

private

  def create(options={})
    PatientProgram.create(patient_program_default_values.merge(options))
  end

end
