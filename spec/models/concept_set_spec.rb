require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptSet do
  # You can move this to spec_helper.rb
  set_fixture_class :concept_set => ConceptSet
  fixtures :concept_set

  sample({
    :concept_id => 1,
    :concept_set => 1,
    :creator => 1,
    :date_created => Time.now
  })

  it "should be valid" do
    #concept_set = create_sample(ConceptSet)
    concept_set = ConceptSet.new(:concept_set => 1, :sort_weight => nil, :creator => 1)
    concept_set.should be_valid
  end
  
end
