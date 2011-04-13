require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptNumeric do
  # You can move this to spec_helper.rb
  set_fixture_class :concept_numeric => ConceptNumeric
  fixtures :concept_numeric

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
