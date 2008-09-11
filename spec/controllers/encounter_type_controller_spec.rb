require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EncounterTypeController do
  fixtures :patient, :encounter, :concept, :location,:patient_identifier,
  :concept_datatype, :concept_class, :order_type, :concept_set, :encounter_type

  before(:each) do
    login_current_user  
    @patient = patient(:andreas)
    session[:patient_id] = @patient.id
  end  

  it "should update params filter" do
    post :update_params_filter
    response.should be_success
  end
   
  it "should create encounter type" do
    post :update_params_filter, :encounter_type => {"encounter_type_id"=>"","name" => "Move file from dormant to active","description" =>"","creator" => User.current_user.id,"date_created" => Time.now}
    response.should be_success
  end
   
    #response.should redirect_to("/patient/menu?")

end
