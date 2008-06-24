require File.dirname(__FILE__) + '/../spec_helper'

describe Observation do
  fixtures :obs

  sample({
    :encounter_id => 2,
    :concept_id => 100,
    :voided => 0,
    :date_created => "2007-03-05 17:37:57".to_time,
    :creator => 1,
    :order_id => nil ,
    :comments => nil,
    :value_datetime => nil ,
    :patient_id => 1,
    :void_reason => nil ,
    :value_boolean => nil,
    :accession_number => nil ,
    :obs_group_id => nil,
    :date_started => nil,
    :location_id => 1,
    :date_stopped => nil,
    :voided_by => nil, 
    :value_drug => nil, 
    :date_voided => nil, 
    :obs_datetime => "2007-03-05 17:37:33".to_time,
    :obs_id =>  1,
    :value_text => nil ,
    :value_modifier => nil ,
    :value_numeric => 66,
    :value_coded => nil ,
    :value_group_id => nil ,
  })

  it "should be valid" do
    obs = create_sample(Observation)
    obs.should be_valid
  end
  
end
