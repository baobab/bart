require File.dirname(__FILE__) + '/../spec_helper'

describe FormentryArchive do
  # You can move this to spec_helper.rb
  set_fixture_class :formentry_archive => FormentryArchive
  fixtures :formentry_archive

  sample({
    :formentry_archive_id => 1,
    :form_data => 'aaaaaaaaaaaaaaaaaaaaaaaaaa aa',
    :date_created => Time.now,
    :creator => 1,
  })

  it "should be valid" do
    formentry_archive = create_sample(FormentryArchive)
    formentry_archive.should be_valid
  end
  
end
