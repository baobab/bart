require File.dirname(__FILE__) + '/../spec_helper'

describe Patient do
  fixtures :users, :global_property, :location, :patient,
    :patient_name, :patient_identifier, :encounter, :patient_address,
    :role, :privilege, :role_privilege, :user_role,
    :concept, :encounter_type, :patient_identifier_type,
    :relationship_type, :program, :drug, :drug_order, :orders, :order_type, :obs

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

  it "should find concept by concept_id" do
    patient(:andreas).observations.find_by_concept_id(concept(:height).id).first.encounter.name.should == "Height/Weight"
  end 

  it "should find concept by concept name" do
    patient(:andreas).observations.find_by_concept_name(concept(:height).name).first.encounter.name.should == "Height/Weight"
  end 

  it "should find first concept by concept name" do
    patient(:andreas).observations.find_first_by_concept_name(concept(:height).name).encounter.name.should == "Height/Weight"
  end 

  it "should find last concept by concept name" do
    patient(:andreas).observations.find_last_by_concept_name(concept(:height).name).encounter.name.should == "Height/Weight"
  end 

  it "should find concept by concept name and date" do
    patient(:andreas).observations.find_by_concept_name_on_date(concept(:height).name,"2007-03-05".to_date).last.encounter.name.should == "Height/Weight"
  end 

  it "should find first concept  by concept name and date" do
    patient(:andreas).observations.find_first_by_concept_name_on_date(concept(:height).name,"2007-03-05".to_date).encounter.name.should == "Height/Weight"
  end 

  it "should find last concept  by concept name and date" do
    patient(:andreas).observations.find_last_by_concept_name_on_date(concept(:height).name,"2007-03-05".to_date).encounter.name.should == "Height/Weight"
  end 

  it "should find first concept on or after a date" do
    patient(:andreas).observations.find_first_by_concept_name_on_or_after_date(concept(:height).name,"2007-03-05".to_date).encounter.name.should == "Height/Weight"
  end 

  it "should find last concept on or after a date" do
    patient(:andreas).observations.find_last_by_concept_name_on_or_before_date(concept(:height).name,"2007-03-05".to_date).encounter.name.should == "Height/Weight"
  end 
  
  it "should find last concept by name before a date" do
    patient(:andreas).observations.find_last_by_concept_name_before_date(concept(:height).name,"2007-03-10".to_date).encounter.name.should == "Height/Weight"
  end 

  it "should find last concept by conditions" do
    result = patient(:andreas).observations.find_last_by_conditions(["concept_id = ? AND DATE(obs_datetime) >= ? AND DATE(obs_datetime) <= ?",concept(:height).id,"2007-03-01".to_date , "2007-03-10".to_date])
    result.encounter.name.should == "Height/Weight"
  end 

  it "should find concepts by concept name with result" do
    result = patient(:andreas).observations.find_by_concept_name_with_result(concept(:is_able_to_walk_unaided).name,"Yes")
    result.last.encounter.name.should == "ART Visit"
  end 

  it "should find first concept by identifier type" do
    result = patient(:andreas).patient_identifiers.find_first_by_identifier_type(patient_identifier_type(:patient_identifier_type_00001).id)
    result.identifier.should == "P170000000013"
  end 

  it "should find encounters by encounter ids" do
    result = patient(:andreas).encounters.find_by_type_id(encounter_type(:height_weight).id)
    result.last.name.should == "Height/Weight"
  end 

  it "should find encounters by encounter name" do
    result = patient(:andreas).encounters.find_by_type_name(encounter_type(:height_weight).name)
    result.last.name.should == "Height/Weight"
  end 

  it "should find encounters by date" do
    result = patient(:andreas).encounters.find_by_date("2007-03-05".to_date)
    result.first.name.should == "ART Visit"
  end 

  it "should find encounters by encounter name and date" do
    result = patient(:andreas).encounters.find_by_type_name_and_date(encounter_type(:height_weight).name,"2007-03-05".to_date)
    result.last.name.should == "Height/Weight"
  end 

  it "should find encounters by encounter name before a date" do
    result = patient(:andreas).encounters.find_by_type_name_before_date(encounter_type(:height_weight).name,"2007-03-06".to_date)
    result.last.name.should == "Height/Weight"
  end 

  it "should find last encounter by encounter name" do
    result = patient(:andreas).encounters.find_last_by_type_name(encounter_type(:height_weight).name)
    result.name.should == "Height/Weight"
  end 

  it "should find first encounter by encounter name" do
    result = patient(:andreas).encounters.find_first_by_type_name(encounter_type(:height_weight).name)
    result.name.should == "Height/Weight"
  end 

  it "should find encounters by conditions" do
    result = patient(:andreas).encounters.find_all_by_conditions(["encounter_type = ? AND DATE(encounter_datetime) >= ? AND DATE(encounter_datetime) <= ?",encounter_type(:height_weight).id,"2007-03-01".to_date , "2007-03-10".to_date])
    result.last.name.should == "Height/Weight"
  end 

  it "should find last encounter by conditions" do
    result = patient(:andreas).encounters.find_last_by_conditions(["encounter_type = ? AND DATE(encounter_datetime) >= ? AND DATE(encounter_datetime) <= ?",encounter_type(:height_weight).id,"2007-03-01".to_date , "2007-03-10".to_date])
    result.name.should == "Height/Weight"
  end 

  it "should find last encounter" do
    result = patient(:andreas).encounters.last
    result.name.should == "Height/Weight"
  end
  
  it "should order" 
  it "should merge" 
  
  it "should add a patient to a program" do
    p = Patient.new()
    p.save
    p.add_program_by_name("HIV")
    p.hiv_patient?.should == true
  end

  it "should add a patient to programs" do
    p = Patient.new()
    p.save
    programs = program(:program_00002), program(:hiv)
    p.add_programs(programs)
    p.patient_programs.length.should == 2
  end

  it "should list available programs for a patient" do
    patient(:andreas).available_programs.first.should == program(:hiv)
  end

  it "should find current encounters by date" do
    encounters = patient(:andreas).current_encounters("2007-03-05".to_date).collect{|e|e.name}
    encounters.should == ["Height/Weight", "Give drugs", "ART Visit"]
  end

  it "should find last encounter by date" do
    encounter = patient(:andreas).last_encounter("2007-03-05".to_date)
    encounter.name.should == "Height/Weight"
  end

  it "should find last encounter name by flow" do
    name = patient(:andreas).last_encounter_name_by_flow("2007-03-05".to_date)
    name.should == "ART Visit"
  end

  it "should find last encounter by flow" do
    name = patient(:andreas).last_encounter_by_flow("2007-03-05".to_date).name
    name.should == "ART Visit"
  end

  it "should find next form" do
    patient = Patient.new()
    patient.save
    form = patient.next_forms
    form.first.name.should == "HIV Reception"
  end

  it "should find current weight" do
    patient(:andreas).current_weight.should == 66.0
  end

  it "should find current visit weight" do
    patient(:andreas).current_visit_weight("2007-03-05".to_date).should == 66.0
  end

  it "should find previous weight" do
    patient(:andreas).previous_weight.should == 66.0
  end

  it "should find percent weight changed" do
    patient(:andreas).percent_weight_changed("2007-03-05".to_date).should == 0.0
  end

  it "should find current height" do
    patient(:andreas).current_height.should == 166.0
  end

  it "should find previous height" do
    patient(:andreas).previous_height.should == 166.0
  end

  it "should find current bmi" do
    patient(:andreas).current_bmi.round.should == 24
  end

  it "should display art therapeutic feeding message" do
    patient(:andreas).art_therapeutic_feeding_message("2007-03-05".to_date).should == ""
  end

  it "should display outcome" do
    patient(:andreas).outcome("2007-03-05".to_date).name.should == "On ART"
  end

  it "should display outcome status" do
    patient(:andreas).outcome_status.should == "Alive and on ART"
  end

  it "should display cohort outcome status" do
    patient(:andreas).cohort_outcome_status("2007-03-05".to_date,"2007-03-05".to_date).should == "Alive and on ART"
  end

  it "should display status - outcome" do
    patient(:andreas).continue_treatment_at_current_clinic("2007-03-05".to_date).should == "Yes"
  end

  it "should display drug orders" do
    patient(:andreas).drug_orders.collect{|o|o.drug.name}.should == ["Stavudine 30 Lamivudine 150 Nevirapine 200", "Abacavir 300"]
  end

  it "should find drug order by drug name" do
    patient(:andreas).drug_orders_by_drug_name("Abacavir 300").last.drug.name.should == "Abacavir 300"
  end

  it "should find drug order date" do
    patient(:andreas).drug_orders_for_date("2007-03-05".to_date).collect{|o|o.drug.name}.should == ["Stavudine 30 Lamivudine 150 Nevirapine 200"]
  end

  it "should find previous drug order date" do
    patient(:andreas).previous_art_drug_orders("2007-03-05".to_date).collect{|o|o.drug.name}.should == ["Stavudine 30 Lamivudine 150 Nevirapine 200"]
  end

  it "should find cohort last art regimen" do
    patient(:andreas).cohort_last_art_regimen.should == "ARV First line regimen"
  end

  it "should find cohort last art drug code" do
    patient(:andreas).cohort_last_art_drug_code.should == "ARV First line regimen"
  end































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
   filing_number_set =  patient(:pete).set_filing_number
   filing_number_set.should == true
  end

  it "should see if patient needs a filing number" do
    patient(:pete).needs_filing_number?.should == true
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
   national_id =  patient(:andreas).set_national_id
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
    patient(:tracy).valid_for_cohort?("2007-10-01".to_date, "2007-12-31".to_date).should == false 
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
    patient = patient(:tracy)
    patient.current_place_of_residence = ("Area 43")
    patient.current_place_of_residence.should == "Area 43"
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

	it "should find patient by patients' place of residence" do
     Patient.find_by_residence("Area 43").last.should == patient(:tracy)
  end

	it "should find patient by patients' place of birth" do
     Patient.find_by_birth_place("Lilongwe City").last.should == patient(:tracy)
  end
	
  it "should find patient by national id" do
    Patient.find_by_national_id("P170000000013").last.should == patient(:andreas)
  end

	it "should find patient by arv number" do
    Patient.find_by_arvnumber("SAL 158").should == patient(:andreas)
  end

  it "should have ordered outcomes" do
    patient = patient(:andreas)
    patient.historical_outcomes.ordered.should_not be_nil

    patient.historical_outcomes.ordered.first.concept.name.should == 'On ART'
    patient.historical_outcomes.ordered.first.outcome_date.should == '2007-03-05'.to_date

    patient.historical_outcomes.ordered('2007-02-28'.to_date).first.outcome_date.should == '2007-02-05'.to_date
  end

end
