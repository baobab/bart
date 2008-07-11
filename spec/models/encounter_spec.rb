require File.dirname(__FILE__) + '/../spec_helper'

describe Encounter do
  fixtures :encounter

  sample({
    :encounter_id => 1,
    :encounter_type => 1,
    :patient_id => 1,
    :provider_id => 1,
    :location_id => 1,
    :form_id => 1,
    :encounter_datetime => Time.now,
    :creator => 1,
    :date_created => Time.now
  })

  it "should be valid" do
    encounter = create_sample(Encounter)
    encounter.should be_valid
     # Eventually we will move this 2008-06-13
    encounter.class.to_s.should == 'Encounter'
  end
  
  it "should get encounter name" do
    encounter(:andreas_art_visit).name.should == "ART Visit"
  end
  
  it "should find by date" do
    Encounter.find_by_date("2007-03-05".to_date).first.should == encounter(:andreas_art_visit)
  end

  it "should be retrospective only if datetime is 1 sec after mid-night" do
    encounter = Encounter.new
    encounter.encounter_datetime = '2008-01-02 00:00:01'
    encounter.should be_retrospective

    encounter.encounter_datetime = '2008-01-02 00:00:02'
    encounter.should_not be_retrospective
  end
  
  it "should be voided if it has no observations" do
    encounter = Encounter.new
    encounter.should be_voided

    encounter_type = EncounterType.new
    encounter_type.name = 'ART Visit'
    encounter_type.save
    encounter.encounter_type = encounter_type.id
    encounter.encounter_datetime = Time.now
    encounter.save

    observation = Observation.new
    observation.encounter_id = encounter.id
    observation.obs_datetime = Time.now
    observation.creator = 1
    observation.concept_id = 1
    observation.value_text = 'Unknown'
    observation.save

    encounter = Encounter.find(observation.encounter.id)
    encounter.should_not be_voided
  end
  
  it "should return type name for name" do
    encounter = Encounter.new
    encounter_type = EncounterType.new
    encounter_type.name = 'ART Visit'
    encounter_type.save
    encounter.encounter_type = encounter_type.id
    encounter.name.should == encounter_type.name
  end
  
  it "should be displayable as a string" do
    encounter = Encounter.new
    encounter.to_s.should == 'Encounter:  Observations:0'

    encounter_type = EncounterType.new
    encounter_type.name = 'ART Visit'
    encounter_type.save

    encounter.encounter_type = encounter_type.id
    encounter.encounter_datetime = Time.now
    encounter.patient_id = 1
    encounter.save
    encounter.to_s.should == 'Encounter:Andreas Jahn ART Visit Observations:0'
  end
 
  it "should produce what was prescribed" do
  end
  
  it "should produce what needs to be dispensed" do
  end
  
  it "should indicate what regimen a patient is on" do
  end

  it "should list encounters falling on a given date" do
  end
  
  it "should list possible next encounter types" do
  end
  
  it "should list patients with encounters of a given type which occured on a specified date" do
  end
  
  it "should count encounters on a specified date by type" do
  end
  
  it "should count patients seen at Reception on a given date" do
  end
  
  it "should indicate if ARV drugs were given" do
  end
  
  it "should save single observations" do
  end
   
  it "should add child observations" do
  end
   
  it "should parse observations" do
  end

  it "should save multiple observations" do
  end

  it "should allow voiding when a reason is given" do
  end

  it "should show the void reason if voided" do
  end

  it "should list check all visits for a specified date and determine if they're valid or not" do
  end

  it "should produce a label" do
  end

  it "should cache encounter regimen names" do
  end
  
end
