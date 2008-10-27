require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ReportsController do
  fixtures :patient, :encounter, :orders, :drug_order, :drug, :concept, 
    :concept_datatype, :concept_class, :order_type, :concept_set

  before(:each) do
    login_current_user  
  end
  
  it "should use ReportsController" do
    controller.should be_an_instance_of(ReportsController)
  end

  it "should display the cohort report" do
    now = Time.new
    Time.stub!(:new).and_return(now)
    get :cohort, :id => 'Q2+2008' 
    response.should_not be_redirect
    response.should be_success        
    assigns(:start_time).should == now
    assigns(:quarter_start).should == "2008-04-01".to_date
    assigns(:quarter_end).should == "2008-06-30".to_date
    
    #messages
    #cohort_values
    #patients_with_visits_or_initiation_in_cohort
  end
  it "should redirect to the report select menu" do
    get :index
    response.should redirect_to(:action => 'select')
  end
  it "should render the menu layout for the supervision action" do
    controller.expect_render(:layout => "layouts/menu")
    get :supervision
  end
  it "should render the menu layout for the select_missing_identifiers action " do
    controller.expect_render(:layout => "layouts/menu")
    get :select_missing_identifiers
  end
  it "should render the menu layout for the select_duplicate_identifiers action" do
    controller.expect_render(:layout => "layouts/menu")
    get :select_duplicate_identifiers
  end
  it "should render the application layout for select_monthly_drug_quantities action" do
    controller.expect_render(:layout => "application")
    get :select_monthly_drug_quantities
  end
  it "should use the default application layout for the select cohort action" do
    controller.expect_render(:layout => "application")
    get :select_cohort
  end  


end
