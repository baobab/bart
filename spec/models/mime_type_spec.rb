require File.dirname(__FILE__) + '/../spec_helper'

describe MimeType do

  sample({
    :mime_type_id => 1,
    :mime_type => '',
    :description => '',
  })

  it "should be valid" do
    mime_type = create_sample(MimeType)
    mime_type.should be_valid
  end
  
end
