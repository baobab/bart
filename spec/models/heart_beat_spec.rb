require File.dirname(__FILE__) + '/../spec_helper'

describe HeartBeat do

  sample({
    :id => 1,
    :ip => '',
    :property => '',
    :value => '',
    :time_stamp => Time.now,
    :username => '',
    :url => '',
  })

  it "should be valid" do
    heart_beat = create_sample(HeartBeat)
    heart_beat.should be_valid
  end
  
end
