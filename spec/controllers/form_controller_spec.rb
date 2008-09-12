require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FormController do
  fixtures :patient, :encounter, :concept, :location, :users,:form,:field,
  :concept_datatype, :concept_class, :order_type, :concept_set, :encounter_type

  before(:each) do
    login_current_user  
  end  
 
  it "should create a form" do
    post :create, :form => {"name"=>"ART Visit","encounter_type"=>2,"published"=>0,"creator"=>User.current_user.id,"date_created"=>Time.now,"retired"=>0,"uri"=>"art_followup","changed_by"=>User.current_user.id,"date_changed"=>Time.now}
    response.should redirect_to("/form/list")
  end

  it "should add a field" do
    post :add_field, :id =>form(:art_visit).form_id,:field_id=>field(:field_00341).field_id
    response.should redirect_to("/form/edit/53")
  end

end
