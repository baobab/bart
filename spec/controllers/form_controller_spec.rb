require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FormController do
  fixtures :patient, :encounter, :concept, :location, :users,:form,:field,
  :concept_datatype, :concept_class, :order_type, :concept_set, :encounter_type

  integrate_views

  before(:each) do
    login_current_user  
  end  
 
  it "should list all forms" do
    get :list
    response.should be_success
  end

  it "should initialize edit a form" do
    post :edit, :id => form(:hiv_first_visit).id
    response.should be_success
  end

  it "should update  a form" do
    post :update, :id => form(:hiv_first_visit).id,
         :form => {"name" =>"name: HIV 1st visit"}
    flash[:notice].should be_eql("Form was successfully updated.")
  end

  it "should initialize a new form" do
    get :new
    response.should be_success
  end

  it "should create a form" do
    post :create, :form => {"name"=>"ART Visit","encounter_type"=>2,"published"=>0,"creator"=>User.current_user.id,"date_created"=>Time.now,"retired"=>0,"uri"=>"art_followup","changed_by"=>User.current_user.id,"date_changed"=>Time.now}
    flash[:notice].should be_eql("Form was successfully created.")
    response.should redirect_to("/form/list")
  end

  it "should add a field" do
    post :add_field, :id =>form(:art_visit).form_id,:field_id=>field(:field_00341).field_id
    flash[:notice].should be_eql("Added: Other symptom")
    response.should redirect_to("/form/edit/53")
  end

  it "should show ask height for adults if we don't already know it" do
    patient = patient(:andreas)
    session[:patient_id] = patient.id
    
    patient.age.should > 18
    obs = patient.observations.find_first_by_concept_name('Height')
    
    patient.current_height.should_not be_nil
    get :show, :id => 47
    response.body.should_not have_text(/id=\"observation_number:6\"/)

    obs.value_numeric = nil
    obs.value_coded = 2
    obs.save
    obs.reload
    patient.current_height.should be_nil

    get :show, :id => 47
    response.body.should have_text(/id=\"observation_number:6\"/)
  end

  it "should show cd 4 percent children only" do
  
  end


end
