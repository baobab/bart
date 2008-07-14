require File.dirname(__FILE__) + '/../spec_helper'

describe FieldType do
  # You can move this to spec_helper.rb
  set_fixture_class :field_type => FieldType
  fixtures :field_type

  sample({
    :field_type_id => 1,
    :name => '',
    :description => '',
    :is_set => false,
    :creator => 1,
    :date_created => Time.now,
  })

  it "should be valid" do
    field_type = create_sample(FieldType)
    field_type.should be_valid
  end
  
  it "should find from ids"

  it "should find by name" do 
    FieldType.find_by_name("select").should == field_type(:field_type_00002)
  end

end
