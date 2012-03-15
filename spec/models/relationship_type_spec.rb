require File.dirname(__FILE__) + '/../spec_helper'

describe RelationshipType do
  # You can move this to spec_helper.rb
  set_fixture_class :relationship_type => RelationshipType
  fixtures :relationship_type

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
