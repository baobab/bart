require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LabelPrintingController do

  before do
    login_current_user
    session[:patient_id] = patient(:andreas).id
    session[:user_edit] = User.current_user.id
    session[:encounter_datetime] = Time.now
  end

  it "should print visit summary" do
    get :print_drug_dispensed
    response.should be_success
  end

  it "should print user label" do
    get :print_user_label
    response.should be_success
  end

  it "should print drug label" do
    post :print_drug_label, :id => drug_barcodes(:drug_barcode_00033).barcode
    response.should be_success
  end

end
