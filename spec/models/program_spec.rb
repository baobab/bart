require File.dirname(__FILE__) + '/../spec_helper'

describe Program do
  # You can move this to spec_helper.rb
  set_fixture_class :program => Program
  fixtures :program

  sample({
    :program_id => 1,
    :concept_id => 1,
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
    program = create_sample(Program)
    program.should be_valid
  end
  
end
