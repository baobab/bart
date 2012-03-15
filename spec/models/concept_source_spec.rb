require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptSource do
  # You can move this to spec_helper.rb
  set_fixture_class :concept_source => ConceptSource
  fixtures :concept_source

  sample({
    :concept_source_id => 1,
    :name => '',
    :description => '',
    :hl7_code => '',
    :creator => 1,
    :date_created => Time.now,
    :voided => 1,
    :voided_by => 1,
    :date_voided => Time.now,
    :void_reason => '',
  })

  it "should be valid" do
    concept_source = create_sample(ConceptSource)
    concept_source.should be_valid
  end
  
end
