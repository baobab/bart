require File.dirname(__FILE__) + '/../spec_helper'

describe Reports::Cohort do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs, :patient_identifier_type

  before(:each) do
    @cohort = Reports::Cohort.new("2007-01-01".to_date, "2007-03-31".to_date)
  end

  it "should include the number of patients started on arv therapy within the specified date range" do
    @cohort.patients_started_on_arv_therapy.should == 1
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
    @cohort.women_started_on_arv_therapy.should == 0
    p = patient(:andreas)
    p.gender = "Female" # sex-change
    p.save!
    @cohort.women_started_on_arv_therapy.should == 1
    @cohort.start_date = "2007-04-01".to_date
    @cohort.end_date = "2007-06-30".to_date
    @cohort.women_started_on_arv_therapy.should == 0
  end
  
  it "should include the number of adults started on arv therapy within the specified date range" do
    @cohort.adults_started_on_arv_therapy.should == 1
    p = patient(:andreas)
    p.birthdate = "2006-01-01".to_date
    p.save!
    @cohort.adults_started_on_arv_therapy.should == 0
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

# Reason for starting
# WHO Stage III
# WHO Stage IV
# CD4 Count
# Lymphocyte count below threshold with WHO Stage 2
# KS

# TB
# EPTB
# Active PTB
# PTB within the past 2 years
# Pregnant women started on ART for PMTCT

  
  it "should count the number for each outcome" do
    @cohort.outcomes[concept(:on_art).id].should == 1
  end
  it "should get the most recent outcome within the period if there are multiple"
  
  it "should get the regimens for those that are Alive and On ART" do
    @cohort.regimens[concept(:stavudine_lamivudine_nevirapine_regimen).id].should == 1
  end
  
  it "should return NULL for patients on unknown regimens (not the previous regimen)"
  
  
  
# Alive and on ART
# Alive and on first line regimen
# Alive and on alternative first line regimen
# Alive and on second line regimen
# Alive and on unknown regimen
# Died
# Defaulted
# Stopped
# Trasferred out

# Of those Alive and On ART
# Ambulatory
# At work/school
# Side effects
#   PN
#   HP
#   SK
# Adults on 1st line regimen with pill count done in the last month of the quarter
# With pill count in the last month of the quarter at 8 or less

# Of those who died
# In month 1
# In month 2
# In month 3
# After month 3


 
end
