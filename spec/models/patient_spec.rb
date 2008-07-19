require File.dirname(__FILE__) + '/../spec_helper'

describe Patient do
  fixtures :users, :global_property, :location, :patient,
    :patient_name, :patient_identifier, :encounter,
    :role, :privilege, :role_privilege, :user_role,
    :concept, :encounter_type, :patient_identifier_type,
    :relationship_type, :program, :drug, :drug_order, :orders, :order_type

  sample({
    :patient_id => 1,
    :gender => '',
    :race => '',
    :birthdate => Time.now.to_date,
    :birthdate_estimated => false,
    :birthplace => '',
    :citizenship => '',
    :mothers_name => '',
    :civil_status => 1,
    :dead => 1,
    :death_date => Time.now,
    :cause_of_death => '',
    :health_district => '',
    :health_center => 1,
    :creator => 1,
    :date_created => Time.now,
    :changed_by => 1,
    :date_changed => Time.now,
    :voided => false,
    :voided_by => 1,
    :date_voided => Time.now,
    :void_reason => '',
  })

  it "should be valid" do
    patient = create_sample(Patient)
    patient.should be_valid
  end
  
  it "should print visit label" do
    patient = patient(:andreas)
    #give_drug_to(patient, Drug.find_by_name("Lopinavir 133 Ritonavir 33"))
    #give_drug_to(patient, Drug.find_by_name("Nevirapine 200"))
    #give_drug_to(patient, Drug.find_by_name("Nelfinavir 250"))
    date = Date.today
    patient.set_last_arv_reg(Drug.find_by_name("Lopinavir 133 Ritonavir 33").name,60,date)
    patient.set_last_arv_reg(Drug.find_by_name("Nelfinavir 250").name,60,date)
    patient.set_last_arv_reg(Drug.find_by_name("Nevirapine 200").name,60,date)
    provider = patient.encounters.find_by_type_name_and_date("ART Visit", date)
	  provider_name = provider.last.provider.username rescue nil
	  provider_name = User.current_user.username if provider_name.blank?
    expected = <<EOF 

N
q801
Q329,026
ZT
A35,30,0,3,1,1,N,"Andreas Jahn (M) P1700-0000-0013"
A35,60,0,3,1,1,N,"#{date.strftime('%d-%b-%Y')} (#{provider_name.upcase})"
A35,90,0,3,1,1,N,"Vitals: no symptoms;"
A35,120,0,3,1,1,N,"Drugs:"
A35,150,0,3,1,1,N,"- Lopinavir 133 Ritonavir 33"
A35,180,0,3,1,1,N,"- Nelfinavir 250"
A35,210,0,3,1,1,N,"- Nevirapine 200"
A35,240,0,3,1,1,N,"Outcome: On ART at MPC"
P2
EOF
    
    patient.drug_dispensed_label(date).to_s.should == expected
  end
  
  it "should set arv number" do
    patient = patient(:andreas)
    patient.arv_number=("MPC 123")
    patient.arv_number.should  == "MPC 123"
  end

  it "should set arv number without arv code" do
    patient = patient(:andreas)
    patient.arv_number=("123")
    patient.arv_number.should  == "MPC 123"
  end
    
	it "should get valid arv number" do
    patient = patient(:andreas)
    patient.arv_number=('MPC 123')
		
    PatientIdentifier.update(patient.id, 'MPC 321', 18, 'Testing valid ARV number')
		patient.arv_number.should == "MPC 321"
	end

  it "should set filing number" do
   patient = patient(:pete)
   filing_number_set = patient.set_filing_number
   filing_number_set.should == true
  end

  it "should see if patient needs a filing number" do
    patient = patient(:pete)
    patient.needs_filing_number?.should == true
  end

  it "should validate national id" do
   Patient.validates_national_id("P170000000013").should == "valid id"
  end

  it "should set next national id" do
   national_id = Patient.next_national_id
   national_id.length.should == 13
   Patient.validates_national_id(national_id).should == "valid id"
  end
  
  it "should set national id" do
   patient = patient(:andreas)
   national_id = patient.set_national_id
   national_id.identifier.length.should == 13
   Patient.validates_national_id(national_id.identifier).should == "valid id"
  end
  
  it "should set archive patient" do
   patient = patient(:johnson)
   sec_patient = patient(:andreas)
   patient.set_filing_number
   Patient.archive_patient(sec_patient.id,patient).should == true
  end
  
  it "should check if valid for cohort?" do
    patient = patient(:tracy)
    patient.valid_for_cohort?("2007-10-01".to_date, "2007-12-31".to_date).should == false 
  end
  
  it "should get cohort case data" do
    patient = patient(:tracy)
    cohort_data = patient.cohort_data("2007-10-01".to_date, "2007-12-31".to_date)
    # case data
    cohort_data["all_patients"].should == 1
    cohort_data["male_patients"].should == 1
    cohort_data["female_patients"].should == 0
    cohort_data["adult_patients"].should == 1
    cohort_data["child_patients"].should == 0
  end
   
  it "should set archive filing number" do
    patient = patient(:andreas)
    patient.set_archive_filing_number
    patient.archive_filing_number.length.should == 10
  end

  it "should set current place of residence" do
    patient = patient(:andreas)
    patient.current_place_of_residence = ("Dedza")
    patient.current_place_of_residence.should == "Dedza"
  end

  it "should set landmark" do
    patient = patient(:andreas)
    patient.landmark =("Bottle store")
    patient.landmark.should == "Bottle store"
  end

  it "should set occupation" do
    patient = patient(:andreas)
    patient.occupation =("Other")
    patient.occupation.should == "Other"
  end

  it "should set guardian" do
    patient(:andreas).art_guardian = (patient(:pete))
    patient(:andreas).art_guardian.should == patient(:pete)
  end

  it "should set hiv test location" do
    patient = patient(:andreas)
    clinic_name=location(:martin_preuss_centre).name
    patient.set_hiv_test_location(clinic_name,Date.today)
    patient.place_of_first_hiv_test.should == clinic_name
  end

  it "should find patient by name" do
    Patient.find_by_name("Jahn").last.should == patient(:andreas)
  end

	it "should find patient by birth year" do
    Patient.find_by_birthyear("1985-04-12").last.should == patient(:tracy)
	end 

	it "should find patient by birth month" do
    Patient.find_by_birthmonth("1985-04-12").last.should == patient(:tracy)
	end 

	it "should find patient by birth day" do
    Patient.find_by_birthday("1985-04-12").last.should == patient(:tracy)
	end 

	it "should find patient by patients' place of residence" 

	it "should find patient by patients' place of birth" 
	
  it "should find patient by national id" do
    Patient.find_by_national_id("P170000000013").last.should == patient(:andreas)
  end

	it "should find patient by arv number" do
    Patient.find_by_arvnumber("SAL 158").should == patient(:andreas)
  end

end
