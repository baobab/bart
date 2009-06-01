require File.dirname(__FILE__) + '/../spec_helper'

describe FormentryArchive do

  sample({
    :formentry_archive_id => 1,
    :form_data => 'aaa',
    :date_created => Time.now,
    :creator => 1,
  })

  it "should be valid" do
    formentry_archive = create_sample(FormentryArchive)
    formentry_archive.should be_valid
  end
  
end
