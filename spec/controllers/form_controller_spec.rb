require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FormController do
  fixtures :patient, :encounter, :concept, :location, :users,:form,
  :concept_datatype, :concept_class, :order_type, :concept_set, :encounter_type

  before(:each) do
    login_current_user  
  end  
 
  it "should create a form" do
    post :create, :form => {"name"=>"ART Visit","encounter_type"=>2,"published"=>0,"creator"=>User.current_user.id,"date_created"=>Time.now,"retired"=>0,"uri"=>"art_followup","changed_by"=>User.current_user.id,"date_changed"=>Time.now}
    response.should redirect_to("form/list")
  end

end
