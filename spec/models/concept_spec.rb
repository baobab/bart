require File.dirname(__FILE__) + '/../spec_helper'

describe Concept do
  fixtures :concept

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

  it "should add to concept_set"
  it "should add concept_answer"
  it "should add yes, no concept answers"
  it "should add yes, no,unknown concept_answers"
  it "should create yes, no, unknown, not applicable concept_answers"
  it "should create start substitute switch answers for regimen type"
  it "should create field"
  it "should humaniz"










end
