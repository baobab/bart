require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptMap do
  # You can move this to spec_helper.rb
  set_fixture_class :concept_map => ConceptMap
  fixtures :concept_map

  sample({
    :concept_map_id => 1,
    :source => 1,
    :source_id => 1,
    :comment => '',
    :creator => 1,
    :date_created => Time.now,
  })

  it "should be valid" do
    concept_map = create_sample(ConceptMap)
    concept_map.should be_valid
  end
  
end
