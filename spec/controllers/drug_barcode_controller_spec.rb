require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DrugBarcodeController do

  before do
    login_current_user
  end

  it "should display a list of drugs with barcode" do
    get :scan
    response.should be_success
  end

  it "should create a new barcode" do
    post :new ,:barcode => "D1000000000021"
    response.should be_success
  end

  it "should find drug by barcode scan" do
    post :scan ,:barcode => "D100000000021"
    response.should be_success
  end

  it "should create a drug barcode" do
    post :save , :barcode =>{"barcode"=>"D100000000021","drug_id"=>"5", "quantity"=>"3"}
    response.should redirect_to("/drug_barcode/scan?barcode=D100000000021")
  end

  it "should display a drug barcode as text" do
    post :to_drug_id , :id => drug_barcodes(:drug_barcode_00033).barcode
    response.should be_success
  end

  it "should display barcode lis" do
    get :index
    response.should redirect_to("/drug_barcode/scan")
  end

end
