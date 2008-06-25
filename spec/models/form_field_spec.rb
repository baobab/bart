require File.dirname(__FILE__) + '/../spec_helper'

describe FormField do
  # You can move this to spec_helper.rb
  set_fixture_class :form_field => FormField
  fixtures :form_field

  sample({
    :form_field_id => 1,
    :form_id => 1,
    :field_id => 1,
    :field_number => 1,
    :field_part => '',
    :page_number => 1,
    :parent_form_field => 1,
    :min_occurs => 1,
    :max_occurs => 1,
    :required => false,
    :changed_by => 1,
    :date_changed => Time.now,
    :creator => 1,
    :date_created => Time.now,
  })

  it "should be valid" do
    form_field = create_sample(FormField)
    form_field.should be_valid
  end
  
end
