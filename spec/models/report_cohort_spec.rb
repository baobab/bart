require File.dirname(__FILE__) + '/../spec_helper'

describe Reports::Cohort do
  before do
    @cohort = Reports::Cohort.new("2007-01-01".to_date, "2007-03-31".to_date)
  end

  it "should include the number of patients started on arv therapy within the specified date range" do
    @cohort.patients_started_on_arv_therapy.should == 2
    @cohort.start_date = "2007-04-01".to_date
    @cohort.end_date = "2007-06-30".to_date
    @cohort.patients_started_on_arv_therapy.should == 0
  end

  it "should include the number of men started on arv therapy within the specified date range" do
    @cohort.men_started_on_arv_therapy.should == 1
    p = patient(:andreas)
    p.gender = "Female" # sex-change
    p.save!
    @cohort.men_started_on_arv_therapy.should == 0
    @cohort.start_date = "2007-04-01".to_date
    @cohort.end_date = "2007-06-30".to_date
    p.gender = "Male" # sex-change
    p.save!
    @cohort.men_started_on_arv_therapy.should == 0
  end

  it "should include the number of women started on arv therapy within the specified date range" do
    @cohort.women_started_on_arv_therapy.should == 1
    p = patient(:andreas)
    p.gender = "Female" # sex-change
    p.save!
    @cohort.women_started_on_arv_therapy.should == 2
    @cohort.start_date = "2007-04-01".to_date
    @cohort.end_date = "2007-06-30".to_date
    @cohort.women_started_on_arv_therapy.should == 0
  end

  it "should include the number of adults started on arv therapy within the specified date range" do
    @cohort.adults_started_on_arv_therapy.should == 2
    p = patient(:andreas)
    p.birthdate = "2006-01-01".to_date
    p.save!
    @cohort.adults_started_on_arv_therapy.should == 1
  end

  it "should include the number of children started on arv therapy within the specified date range" do
    @cohort.children_started_on_arv_therapy.should == 0
    p = patient(:andreas)
    p.birthdate = "2006-01-01".to_date
    p.save!
    @cohort.children_started_on_arv_therapy.should == 1
  end

  it "should count the number for each occupation" do
    occupation = "Healthcare worker"
    p = patient(:andreas)
    p.occupation = occupation
    @cohort.occupations[occupation].should == 1
  end

  it "should not include voided occupations in the count" do
    occupation = "Healthcare worker"
    p = patient(:andreas)
    p.occupation = occupation
    p.occupation = "Ice cream truck driver"
    @cohort.occupations[occupation].should == 0
  end

  it "should not include the most recent occupation" do
    p = patient(:andreas)
    p.occupation = "Shoe salesman"
    p.occupation = "Ice cream truck driver"
    @cohort.occupations["Ice cream truck driver"].should == 1
  end

  it "should count the number for each outcome" do
    PatientHistoricalOutcome.reset
    @cohort.outcomes[concept(:on_art).id].should == 2
  end

  it "should get the regimens for those that are Alive and On ART" do
    @cohort.regimens[concept(:stavudine_lamivudine_nevirapine_regimen).id].should == 1
  end

end
