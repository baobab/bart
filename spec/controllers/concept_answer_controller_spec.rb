require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ConceptAnswerController do

  integrate_views

  before do
    login_current_user
  end

  it "should list concept_answers" do
    pending "Fix this spec when the intended behavior is clear"
    get :list
    response.should be_success
  end

  it "should initialize a new concept_answer" do
    get :new
    response.should be_success
  end

  it "should edit a concept_answer" do
    post :edit , :id => concept_answer(:cough_unknown).id
    response.should be_success
  end

  it "should update a concept_answer" do
    post :update, :id => concept_answer(:cough_unknown).id, :concept_answer =>{"name" => "NSP"}
    response.should render_template("concept_answer/update")
  end

  it "should delete a concept_answer" do
    post :destroy, :id => concept_answer(:cough_unknown).id
    response.should render_template("concept_answer/destroy")
  end

  it "should cancel" do
    post :cancel
    response.should render_template("concept_answer/cancel")
  end


end
