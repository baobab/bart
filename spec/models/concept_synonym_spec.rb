require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptSynonym do

  sample({
    :concept_id => 1,
    :synonym => '',
    :locale => '',
    :creator => 1,
    :date_created => Time.now,
  })

  it "should be valid" do
    concept_synonym = create_sample(ConceptSynonym)
    concept_synonym.should be_valid
  end
  
end
