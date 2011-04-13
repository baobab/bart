require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ObservationController do
#  fixtures :concept_set, :concept
  fixtures :patient, :encounter, :orders, :drug_order, :drug, :concept, 
    :concept_datatype, :concept_class, :order_type, :concept_set

  before(:each) do
    login_current_user  
    @obs = Observation.find(:first)
  end  
 
  it "should get concept" do
    get :concept, :name => concept(:stavudine_lamivudine_nevirapine).name
    response.should be_success
  end

  it "should get edit" do
    get :edit, :id => @obs.id
    response.should be_success
  end
      
  it "should update attributes" do 
    put :update, :id => @obs.id, :observation => { :value_text => "something new" }
    response.should be_redirect
    response.should redirect_to("/encounter/summary")
  end
  
end
