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
  
  it "should cache reports" do
    Report.methods.include?('cache').should be_true
  end

  it "should generate survival analysis hash" do
    Report.survival_analysis_hash(Patient.find(:all), '2007-01-01'.to_date, '2007-03-31'.to_date, '2008-03-31'.to_date, 1).should == {"Defaulted"=>1, "End Date"=> '31 Mar 2007'.to_date, "Start Date"=> '01 Jan 2007'.to_date, "Title"=>"12 month survival: outcomes by end of March 2008", "On ART"=>3, "Transfer out"=>0, "Total"=>4, "Died"=>0, "ART Stop"=>0}
  end

  it "should give a date range given a quarter" do 
    Report.cohort_date_range('Cumulative')[0].should == '2007-02-05'.to_date
    Report.cohort_date_range('Q1_2008').should == ['2008-01-01'.to_date, '2008-03-31'.to_date]
    Report.cohort_date_range('Cumulative')[0].should == '2007-02-05'.to_date
  end
end
