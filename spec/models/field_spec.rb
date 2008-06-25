require File.dirname(__FILE__) + '/../spec_helper'

describe Field do
  # You can move this to spec_helper.rb
  set_fixture_class :field => Field
  fixtures :field

  sample({
    :field_id => 1,
    :name => '',
    :description => '',
    :field_type => 1,
    :concept_id => 1,
    :table_name => '',
    :attribute_name => '',
    :default_value => '',
    :select_multiple => false,
    :creator => 1,
    :date_created => Time.now,
    :changed_by => 1,
    :date_changed => Time.now,
  })

  it "should be valid" do
    field = create_sample(Field)
    field.should be_valid
  end
  
end
