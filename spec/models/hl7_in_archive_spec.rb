require File.dirname(__FILE__) + '/../spec_helper'

describe Hl7InArchive do
  # You can move this to spec_helper.rb
  set_fixture_class :hl7_in_archive => Hl7InArchive
  fixtures :hl7_in_archive

  sample({
    :hl7_in_archive_id => 1,
    :hl7_source => 1,
    :hl7_source_key => '',
    :hl7_data => '',
    :date_created => Time.now,
  })

  it "should be valid" do
    hl7_in_archive = create_sample(Hl7InArchive)
    hl7_in_archive.should be_valid
  end
  
end
