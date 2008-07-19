require File.dirname(__FILE__) + '/../spec_helper'

describe PatientIdentifier do
  fixtures :patient_identifier, :users, :location, :patient

  sample({
    :patient_id => 1,
    :identifier => 'SAL 1588',
    :identifier_type => 18,
    :preferred => 0,
    :location_id => 1,
    :creator => 0,
    :date_created => "2000-01-01 00:00:00".to_time,
    :voided => false,
    :voided_by => nil,
    :date_voided => "2000-01-01 00:00:00".to_time,
    :void_reason => nil,
  })

  it "should be valid" do
    patient_identifier = create_sample(PatientIdentifier)
    patient_identifier.should be_valid
  end
   
  it "should get all patient's identifiers" do
    patient_identifiers = Array.new()
    patient_identifiers << PatientIdentifier.find_by_identifier_type_and_patient_id(3,1)
    patient_identifiers << PatientIdentifier.find_by_identifier_type_and_patient_id(1,1)
    patient_identifiers << PatientIdentifier.find_by_identifier_type_and_patient_id(18,1)
    PatientIdentifier.find_all_by_patient_id(patient(:andreas).id).should == patient_identifiers
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

  it "should set next available arv id" do
    PatientIdentifier.next_available_arv_id.should == "MPC 1"
  end

  it "should calculate checkdigit" do
    PatientIdentifier.calculate_checkdigit(17000000001).should == 3
  end

  it "should get next patient identifier" do
    national_id = PatientIdentifier.get_next_patient_identifier("National id")
    arv_number = PatientIdentifier.get_next_patient_identifier("Arv national id")
    filing_number = PatientIdentifier.get_next_patient_identifier("Filing number")
    archived_filing_number = PatientIdentifier.get_next_patient_identifier("Archived filing number")
    national_id.should == "P170100000011"
    arv_number.should == "MPC 1" 
    filing_number.should == "FN10300001"
    archived_filing_number.should == "FN10400001"
  end
  
  it "should get duplicates by identifier type"
 
 end  
