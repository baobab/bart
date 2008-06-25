require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptDatatype do
  # You can move this to spec_helper.rb
  set_fixture_class :concept_datatype => ConceptDatatype
  fixtures :concept_datatype

  sample({
    :concept_datatype_id => 1,
    :name => '',
    :hl7_abbreviation => '',
    :description => '',
    :creator => 1,
    :date_created => Time.now,
  })

  it "should be valid" do
    concept_datatype = create_sample(ConceptDatatype)
    concept_datatype.should be_valid
  end
  
end
