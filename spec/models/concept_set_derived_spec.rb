require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptSetDerived do

  sample({
    :concept_id => 1,
    :concept_set => 1,
  })

  it "should be valid" do
    concept_set_derived = create_sample(ConceptSetDerived)
    concept_set_derived.should be_valid
  end
  
end
