require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchController do
  fixtures :patient, :encounter, :concept, :location,:patient_identifier,
  :concept_datatype, :concept_class, :order_type, :concept_set, :patient_identifier_type

  before(:each) do
    login_current_user  
  end  
 
  it "should display multiple results"

  it "should show method missing" do
    search_controller = SearchController.new()
    search_controller.method_missing("Patient")
    response.should be_success
  end  
  
  it "should search by identifier type" do
    post :patient_identifier ,:value => "Heal",:type=> patient_identifier_type(:patient_identifier_type_00003).name
    response.should be_success
    response.should have_text("\n  <li id=\"3\">Health Care Worker</li>\n\n")
  end
  
  it "should search by identifier" do
    post :identifier ,:text => "Heal",:type=> patient_identifier_type(:patient_identifier_type_00003).name
    response.should be_success
    response.should have_text("<li>Health Care Worker</li>")
  end
  
  it "should find locations by name" do
    post :health_center_locations ,:value => "light"
    response.should be_success
    response.should have_text("<li>Lighthouse</li>\n<li>Lighthouse HTC</li>")
  end

  it "should show list of location" do
    post :location,:value => "light"
    response.should be_success
  end
  
  it "should find ta by name" do
    post :ta ,:value => "kalo"
    response.should be_success
    response.should have_text("<li>Nkalo</li>\n<li>Kalonga</li>\n<li>Kalolo</li>")
  end
  
  it "should list occupation by name" do
    post :occupation ,:value => "Teac"
    response.should be_success
    response.should have_text("<li>Teacher</li>")
  end
  
  it "should find method missing" do
    post :PatientName, :field=>"given_name",:value=>"and"
    response.should be_success
    response.should have_text("\n  <li id=\"1\">Andreas</li>\n\n")
  end
  

end
