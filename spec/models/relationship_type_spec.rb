require File.dirname(__FILE__) + '/../spec_helper'

describe RelationshipType do

  sample({
    :relationship_type_id => 1,
    :name => '',
    :description => '',
    :creator => 1,
    :date_created => Time.now,
  })

  it "should be valid" do
    relationship_type = create_sample(RelationshipType)
    relationship_type.should be_valid
  end
  
end
