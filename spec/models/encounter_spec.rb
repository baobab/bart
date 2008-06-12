require File.dirname(__FILE__) + '/../spec_helper'

describe Encounter do
  fixtures :encounter

  sample({
    :encounter_id => 1,
    :encounter_type => 1,
    :patient_id => 1,
    :provider_id => 1,
    :location_id => 1,
    :form_id => 1,
    :encounter_datetime => Time.now,
    :creator => 1,
    :date_created => Time.now
  })

  it "should be valid" do
    encounter = create_sample
    encounter.should be_valid
  end
  
end
