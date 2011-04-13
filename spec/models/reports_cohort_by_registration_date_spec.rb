require File.dirname(__FILE__) + '/../spec_helper'

describe Reports::CohortByRegistrationDate do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient,
    :drug_order, :orders, :order_type, :concept, :concept_class, :concept_set,
    :obs, :patient_identifier_type, :person_attribute_type, :global_property

  before(:each) do
    
    @cohort = Reports::CohortByRegistrationDate.new("2007-01-01".to_date, "2007-03-31".to_date)
  end

  it "should include the number of patients started on arv therapy within the specified date range" do
    @cohort.patients_started_on_arv_therapy.length.should == 1
    @cohort.start_date = "2007-04-01".to_date
    @cohort.end_date = "2007-06-30".to_date
    @cohort.patients_started_on_arv_therapy.length.should == 0
  end

  it "should include the number of men started on arv therapy within the specified date range" do
    @cohort.men_started_on_arv_therapy.length.should == 1
    p = patient(:andreas)
    p.gender = "Female" # sex-change
    p.save!
    @cohort.men_started_on_arv_therapy.length.should == 0
    @cohort.start_date = "2007-04-01".to_date
    @cohort.end_date = "2007-06-30".to_date
    p.gender = "Male" # sex-change
    p.save!
    @cohort.men_started_on_arv_therapy.length.should == 0
  end

  it "should include the number of women started on arv therapy within the specified date range" do
    @cohort.women_started_on_arv_therapy.length.should == 0
    p = patient(:andreas)
    p.gender = "Female" # sex-change
    p.save!
    @cohort.women_started_on_arv_therapy.length.should == 1
    @cohort.start_date = "2007-04-01".to_date
    @cohort.end_date = "2007-06-30".to_date
    @cohort.women_started_on_arv_therapy.length.should == 0
  end
  
  it "should include the number of adults started on arv therapy within the specified date range" do
    @cohort.adults_started_on_arv_therapy.length.should == 1
    p = patient(:andreas)
    p.birthdate = "2006-01-01".to_date
    p.save!
    @cohort.adults_started_on_arv_therapy.length.should == 0
  end  
  
  it "should include the number of children started on arv therapy within the specified date range" do
    @cohort.children_started_on_arv_therapy.length.should == 0
    p = patient(:andreas)
    p.birthdate = p.date_started_art - 8.years
    p.save!
    @cohort.children_started_on_arv_therapy.length.should == 1
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
    
    # KS
    o = Observation.new(:creator => 1, :obs_datetime => "2007-01-20".to_date.to_time)
    o.concept_id = Concept.find_by_name("Kaposi's sarcoma").id
    o.value_coded = Concept.find_by_name("Yes").id
    o.encounter_id = encounter.id
    o.patient_id = p.id
    o.save

    # WHO Stage 4
    o = Observation.new(:creator => 1,
          :obs_datetime => "2007-01-20".to_date.to_time,
          :concept_id   =>  Concept.find_by_name('WHO Stage 4 adult'
                                              ).concepts.first.id,
          :value_coded  => Concept.find_by_name("Yes").id,
          :encounter_id => encounter.id,
          :patient => p
    )
    o.save

    p.staging_encounter.should == encounter

    p.who_stage.should == 4
    p.child?.should == false
    p.child_at_initiation?.should == false

    start_date = "2004-01-01".to_date
    end_date = "2007-12-31".to_date
    PersonAttribute.reset
    cohort = Reports::CohortByRegistrationDate.new(start_date, end_date)
    cohort.start_reasons.should == [{"start_cause_PTB"=>0, 
        "WHO stage 4"=>1, "start_cause_EPTB"=>0, "start_cause_KS"=>1,
        "start_cause_APTB"=>0, "Other"=>0}, {}]
  end

  
  it "should count the number for each outcome" do
    @cohort.outcomes[concept(:on_art112).id].should == 1

    pat = patient(:andreas)
    pat.birthdate = Date.today - 8.years
    pat.save
    @cohort.children_outcomes[concept(:on_art112).id].should == 1
  end
  it "should get the most recent outcome within the period if there are multiple"
  
  it "should get the regimens for those that are Alive and On ART" do
    PatientHistoricalRegimen.reset
    @cohort.regimens[concept(:stavudine_lamivudine_nevirapine_regimen234).id].should == 1
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

  it "should list patients with foreign arv numbers" do
    @cohort.patients_with_foreign_arv_number.should == []
    p = patient(:andreas)
    num = p.arv_number
    p.arv_number = "XXX 123"
    p.save
    @cohort.patients_with_foreign_arv_number.should ==
      [p.patient_registration_dates.first]
    p.arv_number = num
    p.save
  end
  
  it "should give list patients with a specified outcome" do
    PatientRegistrationDate.reset
    PatientHistoricalOutcome.reset
    pat = patient(:andreas)
    
    Location.current_location = Location.find(622)
    Location.current_arv_code.should == "SAL"
    pat.arv_number.should =~ /^SAL/
    @cohort.patients_with_outcomes(['On ART']).should ==
      [PatientRegistrationDate.find_by_patient_id(pat.id)]

    @cohort.patients_with_outcomes(['Transferred out',
                                    'Transferred Out (with Note)']).should == []
    
    outcomes = @cohort.outcomes
    outcomes.each do|concept_id, count|
      @cohort.patients_with_outcomes([Concept.find(concept_id).name])
    end
  end

  it "should give list of pregnat women in cohort" do
    @cohort.pregnant_women.should == []
    p = patient(:andreas)
    p.gender = "Female" # sex-change
    p.save!
    p.observations.create!(:concept_id => Concept.find_by_name('Pregnant').id,
      :value_coded => Concept.find_by_name('Yes').id,
      :obs_datetime => p.date_started_art + 7.days,
      :creator => 1,
      :encounter => p.encounters.find_by_encounter_type(2)
    )
    @cohort.pregnant_women.should == 
      [PatientRegistrationDate.find_by_patient_id(p.id)]
  end

  it "should calculate cohort values" do
    values = @cohort.report_values
    values["dead_patients"].should == 0
    values["new_patients"].should == 1
  end

  it "should list adherent patients" 
  it "should list over adherent patients"
  
end
