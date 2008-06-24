require File.dirname(__FILE__) + '/../test_helper'

class PatientTest < Test::Unit::TestCase
  fixtures :users, :global_property, :location, :patient,
    :patient_name, :encounter,
    :role, :privilege, :role_privilege, :user_role,
    :concept, :encounter_type, :patient_identifier_type,
    :relationship_type, :program, :drug, :drug_order, :orders, :order_type

  @@today = Date.today
  @@sixty_days_ago = Date.today - 60
  
  def setup
    super
    User.current_user = users(:registration)
    Location.current_location = location(:martin_preuss_centre)
  end
  
  def teardown
    super
    User.current_user = nil
    Location.current_location = nil
  end

=begin # TODO
  def test_can_set_last_name
    patient = patient(:andreas)
    last_name="Jahn"
    patient.set_last_name(last_name)
    assert patient.last_name == last_name
  end

  def test_can_set_first_name
    patient = patient(:andreas)
    name="andreas"
    patient.set_first_name(name)
    assert patient.first_name == name
  end
=end

  def test_should_not_set_initial_weight_if_vitals_exist
    patient = patient(:andreas)
    assert_raises RuntimeError do
      patient.set_initial_weight(77, @@sixty_days_ago)
    end
    assert patient.initial_weight ==  66
  end

  def test_should_not_set_initial_height_if_vitals_exist
    patient = patient(:andreas)
    assert_raises RuntimeError do
      patient.set_initial_height(177,@@sixty_days_ago)
    end
    assert patient.initial_height ==  166
  end

  def test_can_set_initial_weight
    patient = patient(:pete)
    patient.set_initial_weight(66,@@sixty_days_ago)
    assert patient.initial_weight ==  66
  end

  def test_can_set_initial_height
    patient = patient(:pete)
    patient.set_initial_height(155,@@sixty_days_ago)
    assert patient.initial_height ==  155
  end

  def test_can_set_transfer_in_false
    patient = patient(:andreas)
    patient.set_transfer_in(false, @@sixty_days_ago)
    assert patient.transfer_in? == false
  end

  def test_can_set_transfer_in_true
    patient = patient(:andreas)
    patient.add_program_by_name("HIV")
    patient.set_transfer_in(true, @@sixty_days_ago)
    assert patient.transfer_in? == true
  end

  def test_can_set_current_place_of_residence
    patient = patient(:andreas)
    patient.current_place_of_residence = "Dedza"
    assert patient.current_place_of_residence == "Dedza"
  end

  def test_can_set_landmark
    patient = patient(:andreas)
    patient.landmark = "Bottle store"
    assert patient.landmark == "Bottle store"
  end

  def test_can_set_occupation
    patient = patient(:andreas)
    patient.occupation = "Other"
    assert patient.occupation == "Other"
  end

  def test_can_set_guardian
    patient = patient(:andreas)
    guardian = patient(:pete)
    patient.art_guardian = guardian
    assert patient.art_guardian = guardian
  end
  
  def test_can_set_hiv_test_location
    patient = patient(:andreas)
    clinic_name=location(:martin_preuss_centre).name
    patient.set_hiv_test_location(clinic_name,@@today)
    assert patient.place_of_first_hiv_test == clinic_name
  end

=begin # TODO
  def test_can_set_hiv_test_date
    patient = patient(:andreas)
    patient.set_hiv_test_date(@@sixty_days_ago,@@today)
    assert patient.hiv_test_date.to_date == @@sixty_days_ago
  end
=end  
  
  def test_can_set_side_effects
    patient = patient(:andreas)
    patient.set_art_staging_encounter("Other side effect","Yes",@@today)
    assert patient.requested_observation_by_name_date("Other side effect",@@today)  == "Yes"
  end
  
  def test_can_set_cpt
    patient = patient(:andreas)
    patient.set_art_staging_encounter("Prescribe Cotrimoxazole (CPT)","Yes",@@today)
    assert patient.requested_observation_by_name_date("Prescribe Cotrimoxazole (CPT)",@@today)  == "Yes"
  end

  def test_can_set_ptb
    patient = patient(:andreas)
    patient.set_art_staging_encounter("PTB within the past 2 years","Yes",@@today)
    assert patient.requested_observation_by_name_date("PTB within the past 2 years",@@today)  == "Yes"
  end
  
  def test_can_set_ks
    patient = patient(:andreas)
    patient.set_art_staging_encounter("Kaposi's sarcoma","Yes",@@today)
    assert patient.requested_observation_by_name_date("Kaposi's sarcoma",@@today)  == "Yes"
  end
  
  def test_can_set_pmtct
    patient = patient(:andreas)
    patient.set_art_staging_encounter("Referred by PMTCT","No",@@today)
    assert patient.requested_observation_by_name_date("Referred by PMTCT",@@today)  == "No"
  end
  
  def test_can_set_eptb
    patient = patient(:andreas)
    patient.set_art_staging_encounter("Extrapulmonary tuberculosis (EPTB)","Yes",@@today)
    assert patient.requested_observation_by_name_date("Extrapulmonary tuberculosis (EPTB)",@@today)  == "Yes"
  end
  
  def test_can_set_work_school
    patient = patient(:andreas)
    patient.set_art_visit_encounter("Is at work/school","Yes",@@today)
    assert patient.requested_observation_by_name_date("Is at work/school",@@today)  == "Yes"
  end
  
  def test_can_set_height
    patient = patient(:andreas)
    height=160
    patient.set_last_height(height,@@today)
    assert patient.current_height(@@today)  == height
  end
  
  def test_can_set_weight
    patient = patient(:andreas)
    weight=60.7
    patient.set_last_weight(weight.to_f,@@today)
    assert patient.current_weight(@@today).to_f  == weight.to_f
  end
  
  def test_can_set_outcome
    patient = patient(:andreas)
    patient.set_art_visit_encounter("Outcome", "On ART", @@today)
    assert_equal "On ART", patient.requested_observation_by_name_date("Outcome", @@today)
  end
  
  def test_can_set_last_art_receiver
# TODO
#    patient = patient(:andreas)
#    assert patient.patient_present?(@@today) == true
  end
  
  def test_can_set_amb
    patient = patient(:andreas)
    patient.set_art_visit_encounter("Is able to walk unaided","Yes",@@today)
    assert patient.requested_observation_by_name_date("Is able to walk unaided",@@today)  == "Yes"
  end
  
  def test_can_set_pill_count
    patient = patient(:andreas)
    drug = Drug.find_by_name("Stavudine 30 Lamivudine 150")
    patient.set_art_visit_pill_count(drug.name,4,@@today)
    assert patient.requested_observation_by_name_date("Whole tablets remaining and brought to clinic",@@today).to_i  == 4
    assert patient.observations.find_last_by_concept_name_on_date("Whole tablets remaining and brought to clinic",@@today).value_drug = drug
  end
  
  def test_can_set_last_arv_reg
    patient = patient(:andreas)
    amount=60
    patient.set_last_arv_reg("Stavudine 30 Lamivudine 150",amount,@@today)
    assert patient.drug_orders_for_date(@@today).last.drug.name.to_s  == "Stavudine 30 Lamivudine 150"
    assert patient.drug_orders_for_date(@@today).last.quantity.to_i  == amount
  end
  
  def test_can_set_arv_number
    patient = patient(:andreas)
    arv_number="MPC 123"
    patient.arv_number=(arv_number)
    assert patient.arv_number  == arv_number
  end
 
  def test_can_set_arv_number_without_arv_code
    patient = patient(:andreas)
    arv_number="123"
    patient.arv_number=(arv_number)
    assert_equal Location.current_arv_code + ' ' + arv_number, patient.arv_number
  end

	def test_should_get_valid_arv_number
    patient = patient(:andreas)
    patient.arv_number=('MPC 123')
		
    PatientIdentifier.update(patient.id, 'MPC 321', 18, 'Testing valid ARV number')
		assert_equal 'MPC 321', patient.arv_number
	end
  
  def test_can_set_int_cd4_count
    patient = patient(:andreas)
    cd4_count=158
    cd4_modifier="="
    patient.set_art_staging_int_cd4(cd4_count,cd4_modifier,@@today)
    assert patient.last_cd4_count  == cd4_count
  end
  
  def test_can_set_needs_filing_number?
    patient = patient(:andreas)
    assert patient.needs_filing_number? == true
  end
  
  def test_should_determine_if_patient_needs_cd4_count
    patient = patient(:andreas)
##TODO
##    assert patient.needs_cd4_count?("2007-05-01".to_date) == false
##    assert patient.needs_cd4_count?("2008-05-01".to_date) == true
  end
  
  def test_can_set_validates_national_id(national_id)
   national_id = "P170000000013"
   assert Patient.validates_national_id(national_id) == "valid id"
  end
  
  def test_can_set_next_national_id
#   national_id = Patient.next_national_id
   national_id = Patient.next_national_id
   assert national_id.length == 13
  end
  
  def test_can_set_national_id
   patient = patient(:andreas)
   national_id = patient.set_national_id
   assert national_id.identifier.length == 13
  end
  
  def test_can_set_filing_number_id
   patient = patient(:andreas)
   filing_number_set = patient.set_filing_number
   assert filing_number_set == true
  end
  
  def test_can_set_archive_patient
   patient = patient(:andreas)
   sec_patient = patient(:pete)
   patient.set_filing_number
   assert Patient.archive_patient(sec_patient.id,patient) == true
  end

  def test_can_check_if_valid_for_cohort?
    patient = patient(:andreas)
    assert_equal(false, patient.valid_for_cohort?("2007-10-01".to_date, "2007-12-31".to_date)) 
  end

  def test_can_get_cohort_case_data
    patient = patient(:andreas)
    cohort_data = patient.cohort_data("2007-10-01".to_date, "2007-12-31".to_date)
    # case data
    assert_equal(1, cohort_data["all_patients"])
    assert_equal(1, cohort_data["male_patients"])
    assert_equal(0, cohort_data["female_patients"])
    assert_equal(1, cohort_data["adult_patients"])
    assert_equal(0, cohort_data["child_patients"])
  end

  def test_can_get_cohort_occupations
    patient = patient(:andreas)
    cohort_data = patient.cohort_data("2007-10-01".to_date, "2007-12-31".to_date)

    # occupations
    assert_equal({"Health care worker"=>1}, cohort_data["occupations"])
  end

  def test_can_get_cohort_start_reasons
    patient = patient(:andreas)
    cohort_data = patient.cohort_data("2007-10-01".to_date, "2007-12-31".to_date)
    assert_equal({"Unknown"=>1}, cohort_data["start_reasons"])
    assert_equal(0, cohort_data["start_cause_PTB"])
    assert_equal(0, cohort_data["start_cause_EPTB"])
    assert_equal(0, cohort_data["start_cause_KS"])
    assert_equal(0, cohort_data["start_cause_APTB"])
  end

  def test_can_get_cohort
    patient = patient(:andreas)
    cohort_data = patient.cohort_data("2007-10-01".to_date, "2007-12-31".to_date)
    assert_equal(0, cohort_data["ambulatory_patients"])
    assert_equal(0, cohort_data["transferred_out_patients"])
    assert_equal(0, cohort_data["dead_patients"])
    assert_equal(0, cohort_data["on_1st_line_with_pill_count_adults"])
    assert_equal(0, cohort_data["died_2nd_month"])
    assert_equal(0, cohort_data["other_side_effect_patients"])
    assert_equal(0, cohort_data["lactic_acidosis_patients"])
    assert_equal(0, cohort_data["died_3rd_month"])
    assert_equal(0, cohort_data["died_1st_month"])
    assert_equal(0, cohort_data["working_patients"])
    assert_equal(0, cohort_data["anaemia_patients"])
    assert_equal(0, cohort_data["skin_rash_patients"])
    assert_equal(0, cohort_data["hepatitis_patients"])
    assert_equal(0, cohort_data["died_after_3rd_month"])
    assert_equal({}, cohort_data["regimen_types"])
    assert_equal(1, cohort_data["defaulters"])
    assert_equal(0, cohort_data["adherent_patients"])
    assert_equal(0, cohort_data["art_stopped_patients"])
    assert_equal(0, cohort_data["lipodystropy_patients"])
    assert_equal(0, cohort_data["peripheral_neuropathy_patients"])
  end
  
  def test_should_calculate_next_appointment_date
    # The last drug order was on 2007-03-05 where they were given 60 tablets, 
    # He had remaining 10 tablets, totalling 70 tablets
    # it should be 2 tabs per day (there should be a two day buffer in here)
    patient = patient(:andreas)    
    appointment_date = patient.next_appointment_date("2007-03-05".to_date)
    assert_not_nil appointment_date, "Patient should have an appointment date"  
    assert_equal "2007-04-05".to_date, appointment_date
  end
  
  def test_should_calculate_next_appointment_date_and_skip_easter
    # The last drug order was on 2007-03-11 where they were given 60 tablets, 
    # He had remaining 10 tablets, totalling 70 tablets
    # it should be 2 tabs per day (there should be a two day buffer in here)
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)
    encounter = drug_order.encounter
    encounter.encounter_datetime = "2007-03-08".to_date
    encounter.save
    patient = patient(:andreas)    
    appointment_date = patient.next_appointment_date("2007-03-08".to_date)
    assert_not_nil appointment_date, "Patient should have an appointment date"  
    # Easter is a Sunday, 2007-04-08, when the appointment date with buffer 
    # should land. We subtract two days to Friday because appointments are not
    # supposed to be on weekends. However, that is Good Friday and should be
    # ommitted, so the result should be Thrusday the 5th
    assert_equal "2007-04-05".to_date.to_s, appointment_date.to_s
  end
  
  def test_should_find_date_of_return_if_adherent    
    # The last drug order was on 2007-03-05 where they were given 60 tablets, 
    # He had remaining 10 tablets, totalling 70 tablets
    # it should be 2 tabs per day (there is no buffer in here)
    patient = patient(:andreas)    
    return_date = patient.date_of_return_if_adherent("2007-04-10".to_date)
    assert_not_nil return_date, "Patient should have a return date if they have drugs"  
    assert_equal "2007-04-09".to_date, return_date
  end
  
  def test_should_find_previous_art_drug_orders
    patient = patient(:andreas)
    drug_orders = patient.previous_art_drug_orders("2007-04-01".to_date)
    assert_equal [drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)], drug_orders
  end  

  def test_can_set_archive_filing_number
    patient = patient(:andreas)
    patient.set_archive_filing_number
    assert_equal 10, patient.archive_filing_number.length
  end
  
  def test_can_show_active_or_dormant_patients
    patient = patient(:andreas)
    patient.set_art_staging_encounter("Other side effect","Yes",@@today)
    assert_equal true, patient.active_patient?
  end

  def test_can_show_last_encounter_by_patient
    patient = patient(:andreas)
    patient.set_art_staging_encounter("Other side effect","Yes",@@today)
    assert_equal "HIV Staging", patient.last_encounter_by_patient.name
  end

  def test_can_get_date_started_art_for_patient_with_drug_orders
    patient = patient(:andreas)
    assert_not_nil patient.drug_orders
    assert_not_nil patient.date_started_art
  end

  def test_expected_amount_remaining
    #patient = patient(:andreas)
    #give_drug_to(patient, Drug.find_by_name("Nevirapine 200"))
    #assert_equal patient.expected_amount_remaining(Drug.find_by_name("Nevirapine 200"), "20-March-2007".to_date), 30
  end
  
  def test_expected_drug_dosage
    patient = patient(:andreas)
    #assert_equal prescride_drugs, "Stavudine 30 Lamivudine 150 Nevirapine 200 (1 - 0 - 1)"
  end

  def test_should_merge_patients
    patient_id = patient(:pete).id
    secondary_patient_id = patient(:andreas).id
    encounter_count = patient(:pete).encounters.count
    secondary_encounter_count = patient(:andreas).encounters.count
    count = Patient.count
    Patient.merge(patient_id, secondary_patient_id)
    assert count-1 == Patient.count, "Should have deleted a patient"
    new_patient = Patient.find(patient_id)
    secondary_patient = Patient.find(secondary_patient_id) rescue nil
    assert_nil secondary_patient, "Secondary patient should have been deleted" 
    assert_equal encounter_count+secondary_encounter_count, new_patient.encounters.count
    assert_equal patient_id, Patient.find_by_first_last_sex("Andreas", "Jahn", "Male").first.id, "Should have found Andreas"
    assert_equal patient_id, Patient.find_by_first_last_sex("Pete", "Puma", "Male").first.id, "Should have found Pete"
  end

  def test_should_print_visit_label
    patient = patient(:andreas)
    give_drug_to(patient, Drug.find_by_name("Lopinavir 133 Ritonavir 33"))
    give_drug_to(patient, Drug.find_by_name("Nevirapine 200"))
    give_drug_to(patient, Drug.find_by_name("Nelfinavir 250"))
    expected = <<EOF 

N
q801
Q329,026
ZT
A35,30,0,3,1,1,N,"Andreas Jahn (M) P1700-0000-0013"
A35,60,0,3,1,1,N,"13-Jun-2008 (REGISTRATION)"
A35,90,0,3,1,1,N,"Vitals: no symptoms;"
A35,120,0,3,1,1,N,"Drugs:"
A35,150,0,3,1,1,N,"- Lopinavir 133 Ritonavir 33"
A35,180,0,3,1,1,N,"- Nelfinavir 250"
A35,210,0,3,1,1,N,"- Nevirapine 200"
A35,240,0,3,1,1,N,"Outcome: On ART at MPC"
P2
EOF
    assert_equal expected, patient.drug_dispensed_label(Time.now.to_date)
  end

private

  def create(options={})
    User.create(user_default_values.merge(options))
  end

end
