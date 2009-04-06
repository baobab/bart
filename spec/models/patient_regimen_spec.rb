require File.dirname(__FILE__) + '/../spec_helper'

describe PatientRegimen do

  # If this fails then you need to migrate the views into your test database
  # mysql -u root openmrs_test < db/migrate/regimen.sql
  it "should have the view" do
    PatientRegimen.find(:all).should_not be_empty
  end

  it "should have a dispensation for patients receiving first line regimens" do
    dispensations = patient(:andreas).patient_regimens
    dispensations.size.should == 1
    dispensation = dispensations.first
    dispensation.patient_id.should == patient(:andreas).patient_id
    dispensation.encounter_id.should == encounter(:andreas_drugs).encounter_id
    dispensation.dispensed_date.should == encounter(:andreas_drugs).encounter_datetime
    dispensation.regimen_concept_id.should == concept(:stavudine_lamivudine_nevirapine_regimen).concept_id
  end
  
  it "should have a dispensation for patients receiving first line alternative regimens" do
    # ARV First line regimen alternatives: Zidovudine Lamivudine Nevirapine Regimen, Stavudine Lamivudine Efavirenz Regimen
    encounter = dispense_drugs(patient(:andreas), "2008-04-01 08:00".to_datetime,
      [{:drug => Drug.find_by_name("Efavirenz 600"), :quantity => 30},
       {:drug => Drug.find_by_name("Stavudine 30 Lamivudine 150"), :quantity => 60}])
    dispensations = patient(:andreas).patient_regimens.find(:all, :conditions => ['DATE(dispensed_date) = "2008-04-01"'])
    dispensations.size.should == 1
    dispensation = dispensations.first
    dispensation.patient_id.should == patient(:andreas).patient_id
    dispensation.encounter_id.should == encounter.encounter_id
    dispensation.dispensed_date.to_date.should == encounter.encounter_datetime.to_date
    dispensation.regimen_concept_id.should == concept(:stavudine_lamivudine_efavirenz_regimen).concept_id
  end
  
  it "should have a dispensation for patients receiving second line regimens" do
    # "ARV Second line regimen: Zidovudine Lamivudine Tenofovir Lopinavir/Ritonavir Regimen, Didanosine Abacavir Lopinavir/Ritonavir Regimen"
    encounter = dispense_drugs(patient(:andreas), "2008-04-01 08:00".to_datetime,
      [{:drug => Drug.find_by_name("Abacavir 300"), :quantity => 60},
       {:drug => Drug.find_by_name("Didanosine 200"), :quantity => 30},
       {:drug => Drug.find_by_name("Didanosine 125"), :quantity => 30},
       {:drug => Drug.find_by_name("Lopinavir 200 Ritonavir 50"), :quantity => 120}])
    dispensations = patient(:andreas).patient_regimens.find(:all, :conditions => ['DATE(dispensed_date) = "2008-04-01"'])
    dispensations.size.should == 1
    dispensation = dispensations.first
    dispensation.patient_id.should == patient(:andreas).patient_id
    dispensation.encounter_id.should == encounter.encounter_id
    dispensation.dispensed_date.to_date.should == encounter.encounter_datetime.to_date
    dispensation.regimen_concept_id.should == concept(:didanosine_abacavir_lopinavir_ritonavir_regimen).concept_id
  end
    
  it "should not have a dispensation for patients on unknown regimens" do
    # There is no regimen with Abacavir by itself
    encounter = dispense_drugs(patient(:andreas), "2008-04-01 08:00".to_datetime,
      [{:drug => Drug.find_by_name("Abacavir 300"), :quantity => 60}])
    dispensations = patient(:andreas).patient_regimens.find(:all, :conditions => ['DATE(dispensed_date) = "2008-04-01"'])
    dispensations.size.should == 0
  end  
  
  it "should have multiple entries for patients with multiple dispensations" do
    encounter = dispense_drugs(patient(:andreas), "2008-04-01 08:00".to_datetime,
      [{:drug => Drug.find_by_name("Stavudine 30 Lamivudine 150 Nevirapine 200"), :quantity => 30}])
    dispensations = patient(:andreas).patient_regimens.find(:all)
    dispensations.size.should == 2
    dispensations.map(&:regimen_concept_id).uniq[0].should == concept(:stavudine_lamivudine_nevirapine_regimen).concept_id  
  end
  
  it "should have a dispensation for first line regimen even when other drugs are included" do
    encounter = dispense_drugs(patient(:andreas), "2008-04-01 08:00".to_datetime,
      [{:drug => Drug.find_by_name("Stavudine 30 Lamivudine 150 Nevirapine 200"), :quantity => 30},
       {:drug => Drug.find_by_name("Abacavir 300"), :quantity => 60}])
    dispensations = patient(:andreas).patient_regimens.find(:all)
    dispensations.size.should == 2
    dispensations.map(&:regimen_concept_id).uniq[0].should == concept(:stavudine_lamivudine_nevirapine_regimen).concept_id  
  end

  it "should have a dispensation for first line regimen and second line regimen when it matches both" do
    encounter = dispense_drugs(patient(:andreas), "2008-04-01 08:00".to_datetime,
      [{:drug => Drug.find_by_name("Stavudine 30 Lamivudine 150 Nevirapine 200"), :quantity => 30},
       {:drug => Drug.find_by_name("Abacavir 300"), :quantity => 60},
       {:drug => Drug.find_by_name("Didanosine 200"), :quantity => 30},
       {:drug => Drug.find_by_name("Didanosine 125"), :quantity => 30},
       {:drug => Drug.find_by_name("Lopinavir 200 Ritonavir 50"), :quantity => 120}])
    dispensations = patient(:andreas).patient_regimens.find(:all, :conditions => ['DATE(dispensed_date) = "2008-04-01"'])
    dispensations.size.should == 2
    dispensations[0].regimen_concept_id.should == concept(:stavudine_lamivudine_nevirapine_regimen).concept_id
    dispensations[1].regimen_concept_id.should == concept(:didanosine_abacavir_lopinavir_ritonavir_regimen).concept_id
  end
  
  it "should refer to a patient"
  it "should refer to a regimen concept"
  it "should refer to an encounter"

  # worry about voids
  # worry about retired concepts
end
