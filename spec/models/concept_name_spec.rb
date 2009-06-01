require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptName do
  sample({
    :concept_id => 1,
    :name => '',
    :short_name => '',
    :description => '',
    :locale => '',
    :creator => 1,
    :date_created => Time.now,
  })

  it "should be valid" do
    concept_name = create_sample(ConceptName)
    concept_name.should be_valid
  end
  
end
