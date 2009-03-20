require File.dirname(__FILE__) + '/../spec_helper'

describe Program do

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
  
  it "should find from ids" 

  it "should find by name" do
    Program.find_by_name("HIV").should == program(:hiv)
  end
  
  it "should display program name" do
    program(:hiv).name.should == "HIV"
  end
    
end
