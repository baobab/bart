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
    encounter = create_sample
    encounter.should be_valid
    encounter.class.to_s.should == 'Encounter'
  end
 
  it "should be retrospective only if datetime is 1 sec after mid-night" do
    @encounter = Encounter.new
    @encounter.encounter_datetime = '2008-01-02 00:00:01'
    @encounter.should be_retrospective

    @encounter.encounter_datetime = '2008-01-02 00:00:02'
    @encounter.should_not be_retrospective
  end
  
  it "should be voided if it has no observations" do
    @encounter = Encounter.new
    @encounter.should be_voided

    encounter_type = EncounterType.new
    encounter_type.name = 'ART Visit'
    encounter_type.save
    @encounter.encounter_type = encounter_type.id
    @encounter.encounter_datetime = Time.now
    @encounter.save

    observation = Observation.new
    observation.encounter_id = @encounter.id
#    observation.date_created = Time.now
    observation.obs_datetime = Time.now
    observation.creator = 1
    observation.concept_id = 1
    observation.value_text = 'Unknown'
    observation.save

    @encounter = Encounter.find(observation.encounter.id)
    @encounter.should_not be_voided
  end
  
  it "should return type name for name" do
    @encounter = Encounter.new
    encounter_type = EncounterType.new
    encounter_type.name = 'ART Visit'
    encounter_type.save
    @encounter.encounter_type = encounter_type.id
    @encounter.name.should == encounter_type.name
  end
  
  it "should be stringable" do
  end
  
  it "should produce what was prescribed" do
  end
  
  it "should produce what needs to be dispensed" do
  end
  
  it "should indicate what regimen the patient is on" do
  end
  
  it "should list possible next encounter types" do
  end
  
  it "should save single observations" do
  end
  
  it "should save multiple observations" do
  end
  
end
