require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FieldController do
  fixtures :patient, :encounter, :concept, :location, :users,:field,
  :concept_datatype, :concept_class, :order_type, :concept_set

  before(:each) do
    login_current_user  
  end  
 
  it "should update params filter" do
    get :update_params_filter
    response.should be_success
  end

  it "should initialize a new field" do
    get :new
    response.should be_success
  end

  it "should create a field" do
    post :create,:field => {"name"=>"Recipient of medication","description"=>"","field_type"=>2,"concept_id"=>6,"table_name"=>"","attribute_name"=>"","default_value"=>"","select_multiple"=>0,"creator"=>User.current_user.id,"date_created"=>Time.now,"changed_by"=>"","date_changed"=>""}
    response.should be_success
  end

end
