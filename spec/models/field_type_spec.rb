require File.dirname(__FILE__) + '/../spec_helper'

describe FieldType do

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

  it "should find from ids" do
    FieldType.find_from_ids([11]).should == field_type(:field_type_00011)
    field_type = FieldType.find(11)
    field_type.id = 99
    field_type.save
    FieldType.find(11).id.should == 99  # use cached one
    FieldType.find([11,10]).map(&:id).should == [99,10]
  end

  it "should find by name" do
    FieldType.find_by_name("select").should == field_type(:field_type_00002)
  end

end
