require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptAnswer do

  sample({
    :concept_answer_id => 1,
    :concept_id => 1,
    :answer_concept => 1,
    :answer_drug => nil
  })

  it "should be valid" do
    concept_answer = create_sample(ConceptAnswer)
    concept_answer.should be_valid
  end
   
end
