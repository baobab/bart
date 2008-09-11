require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RoleprivilegeController do 
  fixtures :patient, :encounter, :concept, :location, :users,:role_privilege,
  :concept_datatype, :concept_class, :order_type, :concept_set,:role, :privilege

  before(:each) do
    login_current_user  
    @patient = patient(:andreas)
    session[:patient_id] = @patient.id
    session[:encounter_datetime] = Time.now()
  end  
  
  it "should assign privileges to users" do
    post :create ,:privilege =>{"privilege"=>privilege(:privilege_00078).privilege},:role =>{"role"=>role(:role_00005).role}
    response.should be_success
  end
 
end
