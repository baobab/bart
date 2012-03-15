require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DrugController do
  fixtures :patient, :encounter, :concept, :location, :drug, :drug_barcodes,
  :concept_datatype, :concept_class, :order_type, :concept_set

  before(:each) do
    login_current_user  
    session[:patient_id] = patient(:andreas).id
    session[:encounter_datetime] = Time.now()
  end  
 
  it "should list drugs" do
    get :list
    response.should be_success
  end
 
  it "should initialize a new drug" do
    get :new
    response.should be_success
  end
 
  it "should create a drug" do
    post :create , :drug =>{"concept_id" => concept(:stavudine_lamivudine_nevirapine).id,"name" => "NSP","dose_strength" => 300}
    response.should redirect_to("/drug/list")
  end
  
  it "should edit a drug" do
    post :edit , :id => drug(:drug_00056).id
    response.should be_success
  end
  
  it "should update a drug" do
    post :update ,:id => drug(:drug_00056).id ,:drug =>{"name" => "NSP"}
    response.should redirect_to("/drug/list")
  end
  
  it "should delete a drug" do
    post :destroy ,:id => drug(:drug_00056).id 
    response.should redirect_to("/drug/list")
  end
  
  it "should cancel" do
    post :cancel 
    response.should redirect_to("/drug/list")
  end
  
end
