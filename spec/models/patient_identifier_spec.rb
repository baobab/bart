require File.dirname(__FILE__) + '/../spec_helper'

describe PatientIdentifier do
  it "should create a record" do
    PatientIdentifier.create(patient(:andreas).id,"LLH super","Other name")
    patient(:andreas).other_names.should == 'LLH super'
  end

  it "should get all patient's identifiers" do
    patient_identifiers = Array.new()
    patient_id = patient(:andreas).id
    patient_identifiers << PatientIdentifier.find_by_identifier_type_and_patient_id(3,patient_id)
    patient_identifiers << PatientIdentifier.find_by_identifier_type_and_patient_id(1,patient_id)
    patient_identifiers << PatientIdentifier.find_by_identifier_type_and_patient_id(18,patient_id)
    (PatientIdentifier.find_all_by_patient_id(patient_id) & patient_identifiers).should == patient_identifiers
  end

  it "should find all identifiers by name" do
    occupations = Array.new
    occupations <<  PatientIdentifier.find_by_identifier_type_and_patient_id(3,1)
    occupations <<  PatientIdentifier.find_by_identifier_type_and_patient_id(3,2)
    PatientIdentifier.find_all_by_identifier_type_name("Occupation").should == occupations
  end

  it "should display identifier as string " do
     PatientIdentifier.find_by_identifier_type_and_patient_id(3,1).to_s.should == "Occupation: Health Care Worker"
  end

  it "should update identifier" do
    PatientIdentifier.update(1, 'MPC 9', 18, 'Testing first update')
    PatientIdentifier.find_by_identifier_type(18).identifier.should == "MPC 9"
  end

  it "should calculate checkdigit" do
    PatientIdentifier.calculate_checkdigit(17000000001).should == 3
  end

  it "should get next patient identifier" do
    property = GlobalProperty.find_by_property('filing_number_prefix')
    property.update_attribute(:property_value, "FN103,FN104")

    national_id = PatientIdentifier.get_next_patient_identifier("National id")
    arv_number = PatientIdentifier.get_next_patient_identifier("Arv national id")
    filing_number = PatientIdentifier.get_next_patient_identifier("Filing number")
    archived_filing_number = PatientIdentifier.get_next_patient_identifier("Archived filing number")
    national_id.should == "P170100176509"
    arv_number.should == "MPC 1"
    filing_number.should == "FN10300001"
    archived_filing_number.should == "FN10400001"
  end

  it "should get duplicates by identifier type" do
    PatientIdentifier.duplicates_by_type(PatientIdentifierType.find_by_name("National id")).last.identifier.should == "P170100176493"
  end

 end
