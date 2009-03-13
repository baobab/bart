require File.dirname(__FILE__) + '/../spec_helper'

describe Reports::CohortByStartDate do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order,
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs, :patient_identifier_type

  before do
    @cohort = Reports::CohortByStartDate.new("2007-01-01".to_date, "2007-03-31".to_date)
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
    p.birthdate = Date.today - 10.years
    p.save!
    @cohort.children_started_on_arv_therapy.should == 1
  end

  it "should include the number of infants started on arv therapy within the specified date range" do
    @cohort.infants_started_on_arv_therapy.should == 0
    p = patient(:andreas)
    p.birthdate = Date.today - 1.year
    p.save!
    @cohort.infants_started_on_arv_therapy.should == 1
  end

  it "should include the number of patients who Transferred In and started on arv therapy within the specified date range" do
    @cohort.transfer_ins_started_on_arv_therapy.should == 0
  end

  it "should count the number for each occupation" do
    occupation = "Healthcare worker"
    p = patient(:andreas)
    p.occupation = occupation
    @cohort.occupations[occupation.downcase].should == 1
  end

  it "should not include voided occupations in the count" do
    occupation = "Healthcare worker"
    p = patient(:andreas)
    p.occupation = occupation
    p.occupation = "Ice cream truck driver"
    @cohort.occupations[occupation.downcase].should == 0
  end

  it "should include the most recent occupation" do
    p = patient(:andreas)
    p.occupation = "Shoe salesman"
    p.occupation = "Ice cream truck driver"
    @cohort.occupations["ice cream truck driver"].should == 1
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

  it "should count patients with KS as one their staging conditions" do
    p = patient(:andreas)
    encounter = Encounter.new(:creator => 1, :encounter_type => EncounterType.find_by_name('HIV Staging').id, :encounter_datetime => "2007-01-20".to_date.to_time)
    encounter.patient_id = p.id
    encounter.save
    o = Observation.new(:creator => 1, :obs_datetime => "2007-01-20".to_date.to_time)
    o.concept_id = Concept.find_by_name("Kaposi's sarcoma").id
    o.value_coded = Concept.find_by_name("Yes").id
    o.encounter_id = encounter.id
    o.patient_id = p.id
    o.save
    start_date = "2004-01-01".to_date
    end_date = "2007-12-31".to_date
    cohort = Reports::CohortByStartDate.new(start_date, end_date)
    cohort.start_reasons.should == [{"start_cause_PTB"=>0, "WHO Stage 4"=>1, "start_cause_EPTB"=>0, "start_cause_KS"=>1, "start_cause_APTB"=>0}, {"WHO Stage 4"=>[1]}]
  end


  it "should count the number for each outcome" do
    @cohort.outcomes[concept(:on_art).id].should == 1

    @cohort.child_outcomes[concept(:on_art).id].should == 1
  end
  it "should get the most recent outcome within the period if there are multiple"

  it "should get the regimens for those that are Alive and On ART" do
    #@cohort.regimens[concept(:stavudine_lamivudine_nevirapine_regimen).id].should == 1
    @cohort.regimens.should == 0
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

  it "should give list patients with a specified occupation" do
    @cohort.patients_with_occupations(['Health Care Worker','Healthcare worker']).should == [patient(:andreas)]
  end

  it "should give list patients with a specified outcome" do
    @cohort.patients_with_outcomes(['on art']).should == [patient(:andreas)]
    @cohort.patients_with_outcomes(['Transferred out', 'Transferred Out (with Note)']).should == [patient(:andreas)]
  end

end
