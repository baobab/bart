require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptWord do
  # You can move this to spec_helper.rb
  set_fixture_class :concept_word => ConceptWord
  fixtures :concept_word

  sample({
    :concept_id => 1,
    :word => '',
    :synonym => '',
    :locale => '',
  })

  it "should be valid" do
    concept_word = create_sample(ConceptWord)
    concept_word.should be_valid
  end
  
end
