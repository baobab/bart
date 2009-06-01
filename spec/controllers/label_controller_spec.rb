require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LabelController do

  before do
    login_current_user
    @patient = patient(:andreas)
    session[:patient_id] = @patient.id
    session[:encounter_datetime] = Time.now
  end

  it "should initialize a new label" do
    get :new
    response.should be_success
  end

  it "should print a national id label" do
    post :national_id, :id => @patient.id
    response.should be_success
  end

  it "should print a test label" do
    post :test
    response.should be_success
  end

  it "should print filing number" do
    post :filing_number_only, :id => @patient.id
    response.should be_success
  end

  it "should print filing number and national id" do
    post :filing_number_and_national_id, :id => @patient.id
    response.should be_success
  end

  it "should print transfer out label" do
    post :transfer_out_label, :id => @patient.id, :location => location(:chinthembwe_health_centre).name
    response.should be_success
  end

  it "should create a label" do
    post :create
    response.should be_success
    response.should have_text("\nN\nq801\nQ329,026\nZT\nP1\n")
  end

  it "should design" do
    post :designer
    response.should be_success
    response.should render_template('label/designer')
  end

end
