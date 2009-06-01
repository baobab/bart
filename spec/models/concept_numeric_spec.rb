require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptNumeric do
  sample({
    :concept_id => 1,
    :units => '',
    :precise => false,
  })

  it "should be valid" do
    concept_numeric = create_sample(ConceptNumeric)
    concept_numeric.should be_valid
  end
  
end
