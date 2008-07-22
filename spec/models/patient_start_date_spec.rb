require File.dirname(__FILE__) + '/../spec_helper'

describe PatientStartDate do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs

  # If this fails then you need to migrate the views into your test database
  # mysql -u root openmrs_test < db/migrate/patient_start_dates.sql
  it "should have the view" do
    PatientStartDate.find(:all).should_not be_empty
  end
  
  it "should use the initial first line regimen dispensation as the start date if there is no date of art initiation" do
    encounter = dispense_drugs(patient(:pete), "2006-04-01 08:00".to_datetime,
      [{:drug => Drug.find_by_name("Stavudine 30 Lamivudine 150 Nevirapine 200"), :quantity => 30}])
    start_dates = PatientStartDate.find(:all)
    start_dates.size.should == 2
    start_dates.last.start_date.to_date.should == "2006-04-01".to_date 
    start_dates.last.patient_id.should == patient(:pete).patient_id
  end
  
  it "should use the date of art initiation as the start date if there is no initial first line regimen dispensation" do
    encounter = patient(:pete).encounters.create(:encounter_datetime => Time.new, 
      :encounter_type => encounter_type(:art_visit).encounter_type_id)
    encounter.observations.create(:concept_id => concept(:date_of_art_initiation), 
      :obs_datetime => encounter.encounter_datetime, :value_datetime => "2006-04-01 08:00".to_datetime)
    start_dates = PatientStartDate.find(:all, :conditions => { :patient_id => patient(:pete).patient_id })
    start_dates.size.should == 1
    start_dates.first.start_date.to_date.should == "2006-04-01".to_date 
    start_dates.first.patient_id.should == patient(:pete).patient_id
  end
      
  it "should use date of art initiation when it is first and initial first line regimen dispensation is also present" do
    encounter = dispense_drugs(patient(:pete), "2006-04-01 08:00".to_datetime,
      [{:drug => Drug.find_by_name("Stavudine 30 Lamivudine 150 Nevirapine 200"), :quantity => 30}])
    encounter = patient(:pete).encounters.create(:encounter_datetime => Time.new, 
      :encounter_type => encounter_type(:art_visit).encounter_type_id)
    encounter.observations.create(:concept_id => concept(:date_of_art_initiation), 
      :obs_datetime => encounter.encounter_datetime, :value_datetime => "2006-03-01 08:00".to_datetime)
    start_dates = PatientStartDate.find(:all, :conditions => { :patient_id => patient(:pete).patient_id })
    start_dates.size.should == 1
    start_dates.last.start_date.to_date.should == "2006-03-01".to_date 
  end

  it "should use initial first line regimen dispensation when it is first and date of art initiation is also present" do
    encounter = dispense_drugs(patient(:pete), "2006-03-01 08:00".to_datetime,
      [{:drug => Drug.find_by_name("Stavudine 30 Lamivudine 150 Nevirapine 200"), :quantity => 30}])
    encounter = patient(:pete).encounters.create(:encounter_datetime => Time.new, 
      :encounter_type => encounter_type(:art_visit).encounter_type_id)
    encounter.observations.create(:concept_id => concept(:date_of_art_initiation), 
      :obs_datetime => encounter.encounter_datetime, :value_datetime => "2006-04-01 08:00".to_datetime)
    start_dates = PatientStartDate.find(:all, :conditions => { :patient_id => patient(:pete).patient_id })
    start_dates.size.should == 1
    start_dates.last.start_date.to_date.should == "2006-03-01".to_date 
  end

  it "should not have a start date if there is no first line regimen dispensation and no date of art initiation" do
    start_dates = PatientStartDate.find(:all, :conditions => { :patient_id => patient(:pete).patient_id })
    start_dates.size.should == 0
  end
  
end
