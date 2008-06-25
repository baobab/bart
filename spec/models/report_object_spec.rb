require File.dirname(__FILE__) + '/../spec_helper'

describe ReportObject do
  # You can move this to spec_helper.rb
  set_fixture_class :report_object => ReportObject
  fixtures :report_object

  sample({
    :report_object_id => 1,
    :name => '',
    :description => '',
    :report_object_type => '',
    :report_object_sub_type => '',
    :xml_data => '',
    :creator => 1,
    :date_created => Time.now,
    :changed_by => 1,
    :date_changed => Time.now,
    :voided => false,
    :voided_by => 1,
    :date_voided => Time.now,
    :void_reason => '',
  })

  it "should be valid" do
    report_object = create_sample(ReportObject)
    report_object.should be_valid
  end
  
end
