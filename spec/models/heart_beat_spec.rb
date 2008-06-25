require File.dirname(__FILE__) + '/../spec_helper'

describe HeartBeat do
  # You can move this to spec_helper.rb
  set_fixture_class :heart_beat => HeartBeat
  fixtures :heart_beat

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
