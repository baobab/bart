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
    p = patient(:andreas)
    p.add_programs([program(:hiv)])
    patient(:andreas).available_programs.first.should == program(:hiv)
  end

  it "should find current encounters by date" do
    encounters = patient(:andreas).current_encounters("2007-03-05".to_date).collect{|e|e.name}
    encounters.should == ["Height/Weight", "Give drugs", "ART Visit", "HIV First visit", "HIV Reception"]
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

  it "should create a guardian" do
    patient = patient(:andreas)
    patient.create_guardian("Sean","Carter","Male")
    patient.art_guardian.name.should == "Sean Carter"
  end

  it "should show which patient a guardian is related to" do
    patient = patient(:andreas)
    patient.create_guardian("Sean","Carter","Male")
    guardian = Patient.find(patient.art_guardian.id).art_guardian_of.to_s.should == patient.name
  end

  it "should show patients' name" do
    patient(:andreas).name.should == "Andreas Jahn"
  end

  it "should show patients' name with national id" do
    patient(:andreas).name_with_id.should == "Andreas Jahn P1700-0000-0013"
  end

  it "should show patient's age" do
    patient(:andreas).age.should == 38
  end

  it "should show patient's age in months" do
    patient(:andreas).age_in_months.should == ((Time.now - patient(:andreas).birthdate.to_time)/1.month).floor
  end

  it "should show if patient is a child or not" do
    patient(:andreas).child?.should == false
  end

  it "should show if patient is not a child" do
    patient(:andreas).adult_or_child.should == "adult"
  end

  it "should estimate patients' age" do
    patient = Patient.new
    patient.save
    patient.age=(26).should == 26
  end

  it "should show age at initiation" do
    patient = patient(:andreas)
    date = "2005-09-10".to_date
    patient.set_last_arv_reg(Drug.find_by_name("Lopinavir 133 Ritonavir 33").name,60,date)
    patient.set_last_arv_reg(Drug.find_by_name("Nelfinavir 250").name,60,date)
    patient.set_last_arv_reg(Drug.find_by_name("Nevirapine 200").name,60,date)
    patient.age_at_initiation.should == 35
  end

  it "should show apatient was a child at initiation" do
    patient = patient(:andreas)
    date = "2005-09-10".to_date
    patient.set_last_arv_reg(Drug.find_by_name("Lopinavir 133 Ritonavir 33").name,60,date)
    patient.set_last_arv_reg(Drug.find_by_name("Nelfinavir 250").name,60,date)
    patient.set_last_arv_reg(Drug.find_by_name("Nevirapine 200").name,60,date)
    patient.child_at_initiation?.should == false
  end

  it "should display date started art" do
    patient(:andreas).date_started_art.should == ""
  end

  it "should get identifier" do
    patient(:andreas).get_identifier("National id").should == "P170000000013"
  end
 
  it "should set patient first name" do
    patient = Patient.new
    patient.save
    patient.set_first_name=("Sean")
    patient.first_name.should == "Sean"
  end  

  it "should display first name" do
    patient(:andreas).first_name.should == "Andreas"
  end

  it "should display given name" do
    patient(:andreas).given_name.should == "Andreas"
  end

  it "should display last name" do
    patient(:andreas).last_name.should == "Jahn"
  end

  it "should display family name" do
    patient(:andreas).family_name.should == "Jahn"
  end

  it "should set patient names" do
    patient = Patient.new
    patient.save
    patient.set_name("Sean","James")
    patient.name.should == "Sean James"
  end  
  
  it "should update name" do
    patient_name = PatientName.new()
    patient_name.patient_id = patient(:andreas).id
    patient_name.given_name = "Tray"
    patient_name.family_name = "Songz"
    patient_name.save
    patient(:andreas).update_name!(patient_name,"new name given by patient")
    patient(:andreas).name.should == "Tray Songz"
  end  

  it "should display family name" do
    patient(:andreas).other_names.should == "Mr Lighthouse"
  end

  it "should display filing number" do
    patient(:andreas).filing_number.should == "FN10100001"
  end
  
  it "should display archive filing number" do
    patient(:pete).archive_filing_number.should == "FN10200001"
  end
 
  it "should find patient_to_be_archived"

  it "should archived_patient_old_active_filing_number"
  
  it "should archived_patient_old_dormant_filing_number"

  it "should display printing format of filing number" do
    Patient.printing_filing_number_label(patient(:pete).filing_number).should == "0 00 01"
  end
 
  it "should display patient program" do
    patient(:andreas).art_patient?.should == true
  end  

  it "should display whether patient is on art" do
    patient(:andreas).art_patient?.should == true
  end  

  it "should display patients' arv number" do
    patient(:andreas).ARV_national_id.should == "SAL 158"
  end  

  it "should display arv number" do
    patient(:andreas).arv_number.should == "SAL 158"
  end  

  it "should set patient arv number" do
    patient(:andreas).arv_number=("234").should == "MPC 234"
    patient(:andreas).arv_number.should == "MPC 234"
  end

  it "should find patient by arv number" do
    Patient.find_by_arvnumber(patient(:andreas).arv_number).should == patient(:andreas)
  end

  it "should display patients' national id" do
    patient(:andreas).national_id.should == "P170000000013"
  end  

  it "should display patients' address" do
    patient(:tracy).person_address.should == "Area 43"
  end  

  it "should display patients' printable version of national id" do
    patient(:andreas).print_national_id.should == "P1700-0000-0013"
  end  

  it "should create patients' mastercard"

  it "should display patients' printable version of birthdate" do
    patient(:andreas).birthdate_for_printing.should == "22/Jul/1970"
  end  

  it "should get art initial staging conditions" do
    patient(:pete).art_initial_staging_conditions.should == ["HIV wasting syndrome (weight loss more than 10% of body weight and either chronic fever or diarrhoea in the absence of concurrent illness)"]
  end  

  it "should display patients' WHO" do
    patient(:pete).who_stage.should == 4
  end  

  it "should display patients' reason for art eligibility" do
    patient(:pete).reason_for_art_eligibility.name.should == "WHO stage 4 adult"

    #Testing if a patient in stage 2 without lab result has no reason for art eligibility
    patient = Patient.find(1)
    patient.reason_for_art_eligibility.should be_nil
    patient.who_stage.should == 1
    encounter = Encounter.new
    encounter.patient_id = patient.id
    encounter.type = EncounterType.find_by_name('HIV Staging')
    encounter.encounter_datetime = Time.now
    encounter.save
    observation = Observation.new
    observation.patient_id = patient.id
    observation.encounter_id = encounter.id
    observation.value_coded = 3
    observation.concept = Concept.find_by_name('Herpes zoster')
    observation.obs_datetime = Time.now
    observation.save
    patient.who_stage.should == 2
    patient.reason_for_art_eligibility.should be_nil

    #Now testing if CD4 % is used as reason for starting ART
    patient.age = 2
    encounter = Encounter.new
    encounter.patient_id = patient.id
    encounter.type = EncounterType.find_by_name('HIV Staging')
    encounter.encounter_datetime = Time.now
    encounter.save
    observation = Observation.new
    observation.patient_id = patient.id
    observation.encounter_id = encounter.id
    observation.value_coded = 3
    observation.concept = Concept.find_by_name('CD4 Percentage')
    observation.value_numeric = 12
    observation.obs_datetime = Time.now
    observation.save
    patient.reason_for_art_eligibility.name.should == 'CD4 percentage < 25'

  end  

  it "should get last art prescription" #do
    #patient(:andreas).date_last_art_prescription_is_finished.should == []
  #end  

  it "should get art patients" do
    Patient.art_patients.length.should == 1
  end  

  it "should update defaulters"# do
   # Patient.update_defaulters
  #end  

  it "should say if a patient is a defaulter" do
    patient(:tracy).defaulter?.should == false
  end  

  it "should set transfer in" do
    patient = patient(:andreas)
    patient.set_transfer_in(true,Date.today)
    patient.transfer_in?.should == true
  end  

  it "should display patients' transfer in/out status" do
    patient(:andreas).transfer_in?.should == false
  end  

  it "should say transfer in with letter/not" do
    patient = patient(:andreas)
    patient.set_transfer_in(true,Date.today)
    patient.transfer_in_with_letter?.should == false
  end  

  it "should get previous art visit encounters" do
    patient(:andreas).previous_art_visit_encounters.first.name.should == "ART Visit"
  end  

  it "should get art visit encounters" do
    patient(:andreas).art_visit_encounters("2007-03-05".to_date).first.encounter_datetime.to_date.should == "Mon Mar 05 17:37:27 +0200 2007".to_date
  end  

  it "should get art prescriptions" do
    patient(:andreas).prescriptions("2007-03-05".to_date).collect{|p|p.drug.name}.uniq.to_s.should == "Stavudine 30 Lamivudine 150 Nevirapine 200"
  end  

  it "should get art_quantities including amount remaining after previous visit" do
    patient(:andreas).art_quantities_including_amount_remaining_after_previous_visit("2007-03-05".to_date).collect{|key,value|
      value}.should == [70.0]
  end  

  it "should get art amount remaining if adherent" do
    patient(:andreas).art_amount_remaining_if_adherent("2007-03-05".to_date).collect{|key,value|
      value}.should == [70.0]
  end  

  it "should get number of days overdue" do
    patient(:andreas).num_days_overdue("2007-03-05".to_date).collect{|key,value|
      value}.should == [70.0]
  end  

  it "should display return date by drug" do
    patient(:andreas).return_dates_by_drug("2007-03-05".to_date).values.should == ["Mon, 09 Apr 2007".to_date]
  end  

  it "should display date of return if adherent" do
    patient(:andreas).date_of_return_if_adherent("2007-03-05".to_date).should == "Mon, 09 Apr 2007".to_date
  end  

  it "should get number days overdue by drug" do
    patient(:andreas).num_days_overdue_by_drug("2007-04-15".to_date).values.should == [6]
  end  

  it "should get next appointment date" do
    patient(:andreas).next_appointment_date("2007-03-05".to_date).should == "Thu, 05 Apr 2007".to_date
  end  

  it "should get date for easter" do
    Patient.date_for_easter(2008).should =="Sun, 23 Mar 2008".to_date
  end  

  it "should find patient by first name,last name  and gender" do
    Patient.find_by_first_last_sex("Andreas","Jahn","Male").last.should == patient(:andreas)
  end  

  it "should find patient by name" do
    Patient.find_by_name("Andreas").last.should == patient(:andreas)
  end  

  it "should find patient by birth year" do
    Patient.find_by_birthyear("1970-07-22").first.should == patient(:andreas)
  end  

  it "should find patient by birth month" do
    Patient.find_by_birthmonth("1970-07-22").first.should == patient(:andreas)
  end  

  it "should find patient by birth day" do
    Patient.find_by_birthday("1970-07-22").first.should == patient(:andreas)
  end  

  it "should find patients by esimating birth year" do
    Patient.find_by_age(5,patient(:andreas).birthdate.year).first.should == patient(:andreas)
  end  

  it "should find patient by arv number" do
    Patient.find_by_arv_number(patient(:andreas).arv_number).first.should == patient(:andreas)
  end  

  it "should get patiets' occupation" do
    patient(:andreas).occupation.should == "Health Care Worker"
  end  

  it "should get patient location landmark" do
    patient(:pete).patient_location_landmark.should == "PTC"
  end  

  it "should set patient location landmark" do
    patient(:andreas).patient_location_landmark=("KCH")
    patient(:andreas).patient_location_landmark.should == "KCH"
  end  

  it "should get patiets' address" do
    patient(:tracy).physical_address.should == "Area 43"
  end  

  it "should find patients by patient name" do
    Patient.find_by_patient_name("A","Jahn").last.should == patient(:andreas)
  end  

  it "should find patients by patient names" do
    Patient.find_by_patient_names("A","Mr Lighthouse","Jahn").last.should == patient(:andreas)
  end  

  it "should find patients by patient last names" do
    Patient.find_by_patient_surname("Jahn").last.should == patient(:andreas)
  end  

  it "should validate patients' birthdate" do
    patient = Patient.new()
    patient.birthdate = Date.today + 1.day
    patient.validate.should == ["cannot be in the future"]
  end  

  it "should get total number of patients registered" do
    Patient.total_number_of_patients_registered.should == 1
  end  

  it "should get total number of patients with vitals taken" do
    Patient.today_number_of_patients_with_their_vitals_taken("2007-03-05".to_date).should == 1
  end  

  it "should get number of return visits" do
    Patient.return_visits("Male","2007-02-01".to_date,Date.today).last.values.first.should ==  "P170000000013"
  end  

  it "should get total number of patients by gender/age group" do
    Patient.find_patients_adults("Male","2007-01-01".to_date,Date.today).length.should == 1
  end  

  it "Patient.virtual_register"

  it "should get art clinic name" do
    Patient.art_clinic_name(701).should == "Martin Preuss Centre"
  end  

  it "should get requested observation" do
    patient(:andreas).requested_observation("Height").to_f.should == 166.0
  end  

  it "should get requested observation by name and date" do
    patient(:andreas).requested_observation_by_name_date("Weight","2007-03-05".to_date).to_f.should == 66.0
  end  

  it "should set outcome" do
    patient(:andreas).set_outcome("Died",Date.today)
    patient(:andreas).outcome.name.should == "Died"
  end  

  it "should get place of first hiv test" do
    patient(:andreas).place_of_first_hiv_test.should == "Martin Preuss Centre"
  end  

  it "should display if guardian was present?" do
    patient(:andreas).guardian_present?("2007-03-05".to_date).should == false
  end  

  it "should display if patient was present?" do
    patient(:andreas).patient_present?("2007-03-05".to_date).should == true
  end  

  it "should display if both patient and guardian were present?" do
    patient(:andreas).patient_and_guardian_present?("2007-03-05".to_date).should == false
  end  

  it "should update pmtct"

  it "should display patient visit date" do
    patient(:andreas).patient_visit_date.to_date.should == "2007-03-05".to_date
  end  
  
  it "should get cohort visit data" do
    patient(:andreas).get_cohort_visit_data("2007-02-05".to_date,"2007-04-05".to_date).should == ""
  end  
  
  it "should see if patient is dead or not" do
    patient(:andreas).set_outcome("Died",Date.today)
    patient(:andreas).is_dead?.should == true
  end  
  
  it "should get last visit date given a start date" do
    patient(:andreas).last_visit_date("2007-03-05".to_date).should >= 20
  end  
  
  it "should remove first relationship" 
  
  it "should create national id label" do
    printable_text = <<EOF

N
q801
Q329,026
ZT
B40,180,0,1,5,15,120,N,"P170000000013"
A40,30,0,2,2,2,N,"Andreas Jahn"
A40,80,0,2,2,2,N,"P1700-0000-0013 22/Jul/1970(M)"
A40,130,0,2,2,2,N,""
P1
EOF
    patient(:andreas).national_id_label.should == printable_text
  end  
  
  it "should print filing number label" do
    expected_text = <<EOF

N
q801
Q329,026
ZT
A75,30,0,4,4,4,N,"0   00 01"
A75,150,0,2,2,2,N,"Filing area 01"
A75,200,0,2,2,2,N,"Version number: 1"
P1
EOF
    patient(:andreas).filing_number_label.should == expected_text
  end

  it "should print transfer out label" do
    expected_text = <<EOF

N
q776
Q329,026
ZT
A25,30,0,3,1,1,R,"Martin Preuss Centre transfer out label"
A25,54,0,3,1,1,N,"From MPC to Unknown"
A25,78,0,3,1,1,R,"ARV number: SAL 158"
A25,102,0,3,1,1,N,"Name: Andreas Jahn (M)"
A25,126,0,3,1,1,N,"Age: 38"
A25,150,0,3,1,1,R,"Diagnosis"
A25,174,0,3,1,1,N,"Reason for starting:"
A25,198,0,3,1,1,N,"Art start date:"
A25,222,0,3,1,1,R,"Other diagnosis:"
A25,246,0,3,1,1,R,"Current Status"
A25,270,0,3,1,1,N,"Walk:Y"
P1

N
q776
Q329,026
ZT
A25,30,0,3,1,1,R,"Current art drugs"
A25,54,0,3,1,1,N,"(1) Stavudine 30 Lamivudine 150 Nevirapine 200"
A25,78,0,3,1,1,R,"Transfer out date:"
A25,102,0,3,1,1,N,"#{Date.today.strftime("%d-%b-%Y")}"
P1
EOF
    patient(:andreas).transfer_out_label.should == expected_text
  end

  it "should print archive filing number" do
    patient = Patient.new()
    patient.save
    patient.set_filing_number
    expected_text = <<EOF

N
q801
Q329,026
ZT
A75,30,0,4,4,4,R,"0   00 02"
A75,150,0,2,2,2,N,"MPC archive filing area"
A75,200,0,2,2,2,N,"Version number: 1"
P1
EOF
    patient.archived_filing_number_label.should == expected_text
  end

  it "should show printable version of patients' filing number" do
    Patient.print_filing_number(patient(:andreas).filing_number).should == "0   00 01"
  end

  it "should show printable version patients' outcome" do
    Patient.visit_summary_out_come(patient(:andreas).outcome.name).should == "On ART at MPC"
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
