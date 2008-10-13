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
end
