require File.dirname(__FILE__) + '/../spec_helper'

describe ArtRegisterEntry, "(used as a temporary class for reports, not bound to the database)" do

  it "should be displayable as a string" do
    a = ArtRegisterEntry.new
    a.name = "Dennis Rodman"
    a.sex = "Other"
    a.ambulant = "Yes"
    a.age = 10
    a.to_s.should == "Dennis Rodman Other Yes"
  end

end
