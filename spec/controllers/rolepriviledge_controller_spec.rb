require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RoleprivilegeController do

  before do
    login_current_user
    @patient = patient(:andreas)
    session[:patient_id] = @patient.id
    session[:encounter_datetime] = Time.now()
  end

  it "should create a new privileges" do
    get :new
    response.should be_success
  end

  it "should create aprivillege" do
    post :create ,:privilege =>{"privilege"=>privilege(:privilege_00078).privilege},:role =>{"role"=>role(:role_00005).role}
    flash[:notice].should be_eql("Role Privilege Added")
    response.should be_success
  end

  it "should list privileges" do
    get :list
    response.should be_success
  end

  it "should show privileges" do
    rp = RolePrivilege.find_by_role_id_and_privilege_id(role(:role_00006).id,privilege(:privilege_00086).id)
    get :show, :id => rp.id
    response.should be_success
  end

  it "should edit a privileges" do
    rp = RolePrivilege.find_by_role_id_and_privilege_id(role(:role_00006).id,privilege(:privilege_00086).id)
    post :edit, :id => rp.id
    response.should be_success
  end

end
