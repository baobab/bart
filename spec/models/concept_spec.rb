require File.dirname(__FILE__) + '/../spec_helper'

describe Concept do
  fixtures :concept, :concept_answer

  sample({
    :name => "xCough",
    :datatype_id => 2,
    :date_created => "2008-02-22 16:25:53 +02:00".to_time,
    :creator => 2,
    :is_set => false,
    :class_id => 17,
    :changed_by => 2,
    :units => '', 
    :loinc => '' ,
    :version => '',
    :description => nil,
    :short_name => "Cough",
    :default_charge => '',
    :date_changed => "2008-02-22 16:25:53 +02:00".to_time,
    :form_text => '',
    :retired => false,
    :icd10 => '', 
    :form_location => '', 
    :view_count => '', 
  })

  it "should be valid" do
    concept = create_sample(Concept)
    concept.should be_valid
  end
   
  it "should load cache" do
    Concept.load_cache.first.name.should == "Agrees to followup"
  end

  it "should display concept as string" do
    concept(:cough).to_s.should == "Cough"
  end

  it "should display short name of concepts" do
    concept(:cough).to_short_s.should == "Cough"
  end

  it "should add concept_answer" do
    concept = create_sample(Concept)
    concept.add_yes_no_concept_answers
    concept.concept_answers.map(&:answer_concept).should include(concept(:yes).id, concept(:no).id)
  end

  it "should add yes, no, unknown concept answers" 
  it "should add yes, no, unknown, not applicable concept answers" 
#    concept.add_yes_no_unknown_concept_answers
#    concept.add_yes_no_unknown_not_applicable_concept_answers.should == true

  it "should create start substitute switch answers for regimen type" do
    answers = Concept.create_start_substitute_switch_answers_for_regimen_type
    answers.to_s.should == "StartSubstituteSwitch"
  end
    
  it "should create field" 
# This needs to check that the field was actually created  
#    concept(:cough).create_field.should == true
#  end
    
  it "should humanize concept" 
# This needs to check that the concept name was actually humanized, not just true
#    concept(:cough).humanize.should == true
#  end

end
