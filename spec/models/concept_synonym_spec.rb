require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptSynonym do
  # You can move this to spec_helper.rb
  set_fixture_class :concept_synonym => ConceptSynonym
  fixtures :concept_synonym

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
