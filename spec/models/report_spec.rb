require File.dirname(__FILE__) + '/../spec_helper'

describe Report do
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

  it "should display user encounters by name" do
     encounters = Report.user_stat_data("01-01-2007".to_date,Date.today,users(:mikmck).username)
     encounters['ART Visit'].should == "2007_03_05:3;2007_02_05:1;"
  end

  it "should show weeks when the user encounters occurred" do
     encounters = Report.user_stat_data("01-01-2007".to_date,Date.today,users(:mikmck).username)
     weeks = Report.stats_to_show(encounters['ART Visit'])
     weeks['week_1'].should == ["Mon, 05 Mar 2007: 3", "Tue, 06 Mar 2007", "Wed, 07 Mar 2007", "Thu, 08 Mar 2007", "Fri, 09 Mar 2007", "Sat, 10 Mar 2007", "Sun, 11 Mar 2007"]
  end

  it "should create week days for a given date" do
    Report.create_resuts_for_individual_stats_per_week("01-12-2008".to_date).should ==  ["Mon, 01 Dec 2008", "Tue, 02 Dec 2008", "Wed, 03 Dec 2008", "Thu, 04 Dec 2008", "Fri, 05 Dec 2008", "Sat, 06 Dec 2008", "Sun, 07 Dec 2008"]
  end
  
  it "should show table of results in weeks" do
     encounters = Report.user_stat_data("01-01-2007".to_date,Date.today,users(:mikmck).username)
     weeks = Report.stats_to_show(encounters['ART Visit'])
     Report.detail_user_encounter_results_html(weeks,'ART Visit',users(:mikmck).username).should =="<tr><td><input class='test_name' type=\"button\" onmousedown=\"document.location='/reports/user_stats_graph?id=3,0,0,0,0,0,0&date=05-Mar-2007&user_name=mikmck&stat_name=ART Visit';\" value=\"05-Mar-2007 - 11-Mar-2007\"/></td><td class='data_td'> 3</td><td class='data_td'></td><td class='data_td'></td><td class='data_td'></td><td class='data_td'></td><td class='data_td'></td><td class='data_td'></td><td class='data_totals_td'>3</td></tr><tr><td><input class='test_name' type=\"button\" onmousedown=\"document.location='/reports/user_stats_graph?id=1,0,0,0,0,0,0&date=05-Feb-2007&user_name=mikmck&stat_name=ART Visit';\" value=\"05-Feb-2007 - 11-Feb-2007\"/></td><td class='data_td'> 1</td><td class='data_td'></td><td class='data_td'></td><td class='data_td'></td><td class='data_td'></td><td class='data_td'></td><td class='data_td'></td><td class='data_totals_td'>1</td></tr>"
  end

end
