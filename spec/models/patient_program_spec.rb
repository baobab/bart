require File.dirname(__FILE__) + '/../spec_helper'

describe PatientProgram do
  # You can move this to spec_helper.rb
  set_fixture_class :patient_program => PatientProgram
  fixtures :patient_program

  sample({
    :patient_program_id => 1,
    :patient_id => 1,
    :program_id => 1,
    :date_enrolled => Time.now,
    :date_completed => Time.now,
    :creator => 1,
    :date_created => Time.now,
    :changed_by => 1,
    :date_changed => Time.now,
    :voided => false,
    :voided_by => 1,
    :date_voided => Time.now,
    :void_reason => '',
  })

  it "should be valid" do
    patient_program = create_sample(PatientProgram)
    patient_program.should be_valid
  end
  
end
