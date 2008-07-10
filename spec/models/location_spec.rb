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

  it "should display fixture name" do
    location(:lighthouse).to_fixture_name.should == "lighthouse"
  end 
   
  it "should display current location" do
    Location.current_location.should == location(:lighthouse)
  end
  
  it "should find name like" do
    Location.find_like_name("Lighthouse").first.name.should == "Lighthouse"
  end
  
  it "should display current health center" do
    Location.current_health_center.should == location(:lighthouse).name
  end
	
  it "should display current arv code" do
    description = Location.current_location.description
    description.match(/arv code:(...)/)[0].split(":").last.should == "LLH"
  end
  
  
  it "should display health centers" do
    Location.health_centers("house").last.name.should == "New Statehouse Dispensary"
  end
  
  it "should display health center room"
  
  it "should import locations"
  
  it "should search for health centers"
  
  it "should display list of locations" do
    Location.get_list.first.should == "Amidu"
  end  

end
