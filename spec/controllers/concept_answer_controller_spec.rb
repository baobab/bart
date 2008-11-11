require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ConceptAnswerController do
  fixtures :concept_answer, :encounter, :concept, :location, :drug, :drug_barcodes,
  :concept_datatype, :concept_class, :order_type, :concept_set

  before(:each) do
    login_current_user  
  end  
 
  it "should list concept_answers" do
    get :list
    response.should be_success
  end
  
  it "should initialize a new concept_answer" do
    get :new
    response.should be_success
  end
  
#  it "should create a concept_answer" do
#    post :create , :concept_answer =>{"concept_id" => concept(:stavudine_lamivudine_nevirapine).id,"name" => "NSP","dose_strength" => 300}
#    response.should redirect_to("/concept_answer/list")
#  end
  
  it "should edit a concept_answer" do
    post :edit , :id => concept_answer(:cough_unknown).id
    response.should be_success
  end
  
  it "should update a concept_answer" do
    post :update ,:id => concept_answer(:cough_unknown).id ,:concept_answer =>{"name" => "NSP"}
    response.body.should have_text(' ')
    response.should redirect_to("/concept_answer/list")
  end
  
  it "should delete a concept_answer" do
    post :destroy ,:id => concept_answer(:cough_unknown).id 
    response.should redirect_to("/concept_answer/list")
  end
  
  it "should cancel" do
    post :cancel 
    response.should redirect_to("/concept_answer/list")
  end
  

end
