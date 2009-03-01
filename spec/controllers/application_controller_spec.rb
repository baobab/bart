require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationController do
  fixtures :patient, :encounter, :concept, :location, :users,
  :concept_datatype, :concept_class, :order_type, :concept_set

  before(:each) do
    login_current_user
  end

  it "should authorize" do
    session[:user_id] = nil
    post :authorize
    response.should redirect_to("/user/login")
  end

  it "should make a local request?" do
    post :local_request?
    response.should be_success
  end

  it "should print and redirect" do
    response.template = ActionView::Base.new
    controller.send(:assign_shortcuts, request, response)
    controller.print_and_redirect("/label/national_id/600", "/patient/set_patient/600")
    response.should render_template('shared/_print_and_redirect')
  end


  it "should rescue action in public"
  it "should rescue action"
  it "should create new_encounter_from_form"
  it "should create new_encounter"
  it "should create new_encounter_from_encounter_type_id"
  it "should estimate_outcome_date"
  it "should subtract_months"
  
end
