require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DrugOrderController do

  before do
    login_current_user
    session[:patient_id] = patient(:andreas).id
    session[:encounter_datetime] = Time.now()
  end

  it "should dispense" do
    get :dispense
    response.should be_success
  end

  it "should give out recommended prescription" do
    get :recommended_prescription, :regimen => "Zidovudine Lamivudine Nevirapine"
    response.should be_success
  end

  it "should create a prescription" do
    post :create, :dispensed => { "1" => { "quantity" => "30", "packs" => "1" } }
    response.should render_template("shared/_print_and_redirect")
  end

  it "should display prescribed dosages" do
  end

end
