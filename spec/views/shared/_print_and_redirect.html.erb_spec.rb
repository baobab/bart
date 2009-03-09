require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "shared/print_and_redirect" do
  before do
    render :partial => "shared/print_and_redirect",
           :locals => {:print_url => "/label/national_id/600",
                       :redirect_url => "/patient/set_patient/600",
                       :message => "Printing", :show_next_button => false,
                       :patient_id => 600}
  end

  it "generates an iframe for the print url" do
    response.should have_tag("iframe[src=?]", "/label/national_id/600")
  end

  it "generates Javascript containing the redirect url" do
    response.body.should include("document.location = '/patient/set_patient/600'")
  end

  it "calls the redirect function after a timeout" do
    js = "setTimeout(redirect, 2000);"
    response.should have_tag("script", /#{Regexp.escape(js)}/)
  end
end
