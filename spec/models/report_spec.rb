require File.dirname(__FILE__) + '/../spec_helper'

describe Report do
  # You can move this to spec_helper.rb
  set_fixture_class :report => Report
  fixtures :report

  sample({
    :report_id => 1,
    :name => '',
    :description => '',
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
    report = create_sample(Report)
    report.should be_valid
  end
  
end
