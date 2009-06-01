require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RolePriviledgeController do

  before do
    login_current_user
    @patient = patient(:andreas)
    session[:patient_id] = @patient.id
    session[:encounter_datetime] = Time.now()
  end

  it "should create a user privilege" do
    post :create ,:privilege =>{"privilege"=>privilege(:privilege_00078).privilege}
    response.should redirect_to("/role_priviledge/list")
  end

  it "should show privilege" do
    post :show ,:id => privilege(:privilege_00078).id
    response.should be_success
  end

end
