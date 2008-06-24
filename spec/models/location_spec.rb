require File.dirname(__FILE__) + '/../spec_helper'

describe Location do
  fixtures :location

  sample({
    :name => "Chinthembwe Health Centre",
    :address1 => nil,
    :state_province => nil, 
    :postal_code => nil,
    :latitude => nil,
    :date_created => "2006-11-07 11:24:03 +02:00".to_time,
    :creator => 1,
    :address2 => nil,
    :city_village => nil,
    :country => nil,
    :location_id => 93,
    :description => "Health Centre , Private Health Facility",
    :longitude => nil,
    :parent_location_id => nil,
  })

  it "should be valid" do
    location = create_sample(Location)
    location.should be_valid
  end
  
end
