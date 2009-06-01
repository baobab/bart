require File.dirname(__FILE__) + '/../spec_helper'

describe Reports::CohortByStartDate do
  before do
    @cohort = Reports::CohortByStartDate.new("2007-01-01".to_date, "2007-03-31".to_date)
  end

  it "should include the number of patients started on arv therapy within the specified date range" do
    @cohort.patients_started_on_arv_therapy.size.should == 2
    @cohort.start_date = "2007-04-01".to_date
    @cohort.end_date = "2007-06-30".to_date
    @cohort.patients_started_on_arv_therapy.size.should == 0
  end

  it "should include the number of men started on arv therapy within the specified date range" do
    @cohort.men_started_on_arv_therapy.size.should == 1
    p = patient(:andreas)
    p.gender = "Female" # sex-change
    p.save!
    @cohort.men_started_on_arv_therapy.size.should == 0
    @cohort.start_date = "2007-04-01".to_date
    @cohort.end_date = "2007-06-30".to_date
    p.gender = "Male" # sex-change
    p.save!
    @cohort.men_started_on_arv_therapy.size.should == 0
  end

  it "should include the number of women started on arv therapy within the specified date range" do
    @cohort.women_started_on_arv_therapy.length.should == 1
    p = patient(:andreas)
    p.gender = "Female" # sex-change
    p.save!
    @cohort.women_started_on_arv_therapy.length.should == 2
    @cohort.start_date = "2007-04-01".to_date
    @cohort.end_date = "2007-06-30".to_date
    @cohort.women_started_on_arv_therapy.length.should == 0
  end

  it "should include the number of adults started on arv therapy within the specified date range" do
    @cohort.adults_started_on_arv_therapy.size.should == 2
    p = patient(:andreas)
    p.update_attribute(:birthdate, "2006-01-01".to_date)
    @cohort.adults_started_on_arv_therapy.size.should == 1
  end

  it "should include the number of children started on arv therapy within the specified date range" do
    @cohort.children_started_on_arv_therapy.size.should == 0
    p = patient(:andreas)
    p.birthdate = Date.today - 10.years
    p.save!
    @cohort.children_started_on_arv_therapy.size.should == 1
  end

  it "should include the number of infants started on arv therapy within the specified date range" do
    @cohort.infants_started_on_arv_therapy.size.should == 0
    p = patient(:andreas)
    p.birthdate = Date.today - 1.year
    p.save!
    @cohort.infants_started_on_arv_therapy.size.should == 1
  end

  it "should include the patients who Transferred In and started on arv therapy within the specified date range" do
    @cohort.transfer_ins_started_on_arv_therapy.should == []
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
    cohort.start_reasons.first["start_cause_KS"].should == 1
  end

  it "should count the number for each outcome" do
    PatientHistoricalOutcome.reset
    @cohort.outcomes[concept(:on_art).id].should == 2
  end

  it "should get the regimens for those that are Alive and On ART" do
    @cohort.regimens.size.should == 1
  end

  it "should give list patients with a specified occupation" do
    @cohort.patients_with_occupations(['Health Care Worker','Healthcare worker']).should == [patient(:andreas)]
  end

  it "should give list patients with a specified outcome" do
    #@cohort.patients_with_outcomes(['on art']).should == [patient(:andreas)]
    #@cohort.patients_with_outcomes(['Transferred out', 'Transferred Out (with Note)']).should == [patient(:andreas)]
    PatientHistoricalOutcome.reset
    patient = patient(:andreas)
    @cohort.patients_with_outcomes(['on art']).should include(patient)
    patient1 = @cohort.patients_with_outcomes(['Transfer out'])
    patient2 = @cohort.patients_with_outcomes(['Transfer Out(With Transfer Note)'])
  end
end

