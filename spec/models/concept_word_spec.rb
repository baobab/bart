require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptWord do

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
