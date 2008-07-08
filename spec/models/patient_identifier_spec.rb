require File.dirname(__FILE__) + '/../spec_helper'

describe PatientIdentifier do
  set_fixture_class :patient_identifiers => PatientIdentifier
  fixtures :patient_identifier, :users, :location

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
   
	it "should update identifier" do
    PatientIdentifier.update(1, 'MPC 999', 18, 'Testing second update')
    puts "***#{PatientIdentifier.find_by_identifier_type_and_patient_id(18,1)}"
    PatientIdentifier.update(1, 'MPC 9', 18, 'Testing first update')
    PatientIdentifier.find_by_identifier_type(18).identifier.should == "MPC 9"
	end

  it "should set next available arv id" do
    PatientIdentifier.next_available_arv_id.should == "LLH 1"
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
    arv_number.should == "LLH 1" 
    filing_number.should == "FN10300001"
    archived_filing_number.should == "FN10400001"
  end

end
