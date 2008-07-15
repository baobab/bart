require File.dirname(__FILE__) + '/../spec_helper'

describe Report do
  # You can move this to spec_helper.rb
  set_fixture_class :report => Report
  fixtures :report

  sample({
    :report_id => 1,
    :name => '',
    :description => '',
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
    report = create_sample(Report)
    report.should be_valid
  end
  
  it "should cache reports"
  it "should generate survival analysis hash"
  it "should give a date range given a quarter" do 
    Report.cohort_date_range('Q1 2008').should == ['2008-01-01'.to_date, '2008-03-31'.to_date]
  end
end
