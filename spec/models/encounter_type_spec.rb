require File.dirname(__FILE__) + '/../spec_helper'

describe EncounterType do
  fixtures :encounter_type, :form
  
  sample({
    :encounter_type_id => 1,
    :name => 'Sample Encounter Type',
    :description => 'This is just a sample'
  })
  
  it "should be valid" do
    encounter_type = create_sample
    encounter_type.should be_valid
  end

  it "should map to a url" do
    encounter_type(:hiv_reception).url.should == "/form/show/#{form(:hiv_reception).id}"
    encounter_type(:give_drugs).url.should == "/drug_order/dispense"
    encounter_type(:update_outcome).url.should == "/patient/update_outcome"
    create_sample.url.should be_nil
  end
  
  it "should be cached" do
    EncounterType.should be_cached
  end
end
