require File.dirname(__FILE__) + '/../spec_helper'

describe Relationship do
  # You can move this to spec_helper.rb
  set_fixture_class :relationship => Relationship
  fixtures :relationship

  sample({
    :relationship_id => 1,
    :person_id => 1,
    :relationship => 1,
    :relative_id => 1,
    :creator => 1,
    :date_created => Time.now,
    :voided => false,
    :voided_by => 1,
    :date_voided => Time.now,
    :void_reason => '',
  })

  it "should be valid" do
    relationship = create_sample(Relationship)
    relationship.should be_valid
  end
  
end
