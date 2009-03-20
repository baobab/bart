require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptClass do

  sample({
    :concept_class_id => 99,
    :name => '',
    :description => '',
    :creator => 1,
    :date_created => Time.now,
  })

  it "should be valid" do
    concept_class = create_sample(ConceptClass)
    concept_class.should be_valid
  end
  
end
