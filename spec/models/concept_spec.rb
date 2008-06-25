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
   
end
