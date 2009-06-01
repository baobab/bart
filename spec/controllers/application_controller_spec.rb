require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationController do

  before do
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
    controller.send(:initialize_template_class, response)
    controller.send(:assign_shortcuts, request, response)
    controller.print_and_redirect("/label/national_id/600", "/patient/set_patient/600")
    response.should render_template('shared/_print_and_redirect')
  end


end
