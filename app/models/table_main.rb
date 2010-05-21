class TableMain < OpenMRS
  set_table_name "tblMain"
   
  def self.create_patients
    current_location = Location.current_location
    User.current_user = User.find(1)
    hiv_staging_encounter = EncounterType.find_by_name("HIV Staging")
    hiv_first_visit_encounter = EncounterType.find_by_name("HIV First visit")
    hiv_reception_encounter = EncounterType.find_by_name("HIV Reception")
    height_weight_encounter = EncounterType.find_by_name("Height/Weight")
    art_visit_encounter = EncounterType.find_by_name("ART Visit")
    give_drugs_encounter = EncounterType.find_by_name("Give drugs")

    yes = Concept.find_by_name("Yes")
    no = Concept.find_by_name("No")
    unknown = Concept.find_by_name("Unknown")


    count = 0
    count2 = 0
    patients = self.find(:all)
    patients.each do |rec|
      date_created = rec.RegDate.to_time rescue Time.now()
      patient_id = rec.PatientID
      puts "::::::::::creating patient id -  #{patient_id}"
      #Patient demographics
      sex = rec.Gender.to_i rescue nil
      gender = sex == 1 ? "Male" : "Female"
      voided = rec.Valid == 0 ? "0" : "1"
      dob = "#{rec.DOBYear}-#{rec.DOBMonth}-#{rec.DOBDay}".to_date rescue nil
      estimated_age = rec.CalcAge || rec.ManualAge
      birthdate_est = 0
      if dob.blank? and estimated_age 
        dob = "01-07-#{date_created.year - estimated_age.to_i}".to_date rescue nil
        birthdate_est = 1
      end  

      ta = rec.TraditionalAuthority.gsub("//","").gsub("\\","") rescue nil
      city_village = rec.PatientLocation.gsub("//","").gsub("\\","") rescue nil
      physical_address = rec.Village.gsub("//","").gsub("\\","") rescue nil
      if physical_address == "*** SEE NOTES ***" or physical_address.blank?
        physical_address = rec.DemographicNotes.gsub("//","").gsub("\\","") rescue nil
      end
      given_name = rec.Name.gsub("//","").gsub("\\","").split(' ')[0] rescue nil
      family_name = rec.Name.gsub("//","").gsub("\\","").split(' ')[1] rescue given_name
      phone_number = rec.PhoneNumber.gsub(/ /,'') rescue nil

      next if family_name.blank?
      next if family_name.include?("?")
    
      #city_village =  city_village.delete("\\")
      #puts "#{city_village} ================"
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient
(patient_id,gender,birthdate,birthdate_estimated,creator,date_created,voided)
VALUES (#{patient_id},'#{gender}','#{dob}',#{birthdate_est},1,'#{date_created.to_date}',#{voided});
EOF

    
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_name
(patient_id,given_name,family_name,creator,date_created,voided)
VALUES (#{patient_id},"#{given_name}","#{family_name}",1,'#{date_created.to_date}',#{voided});
EOF

if city_village
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_address
(patient_id,city_village,creator,date_created,voided)
VALUES (#{patient_id},"#{city_village}",1,'#{date_created.to_date}',#{voided});
EOF
end

if physical_address
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_identifier
(patient_id,identifier,identifier_type,creator,date_created,location_id,voided)
VALUES (#{patient_id},"#{physical_address}",6,1,'#{date_created.to_date}',#{current_location.id},#{voided});
EOF
end

if ta
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_identifier
(patient_id,identifier,identifier_type,creator,date_created,location_id,voided)
VALUES (#{patient_id},"#{ta}",9,1,'#{date_created.to_date}',#{current_location.id},#{voided});
EOF
end

if phone_number
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_identifier
(patient_id,identifier,identifier_type,creator,date_created,location_id,voided)
VALUES (#{patient_id},"#{phone_number}",11,1,'#{date_created.to_date}',#{current_location.id},#{voided});
EOF
end

if rec.Occupation
  occupation = TableList.person_occupation(rec.Occupation)
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_identifier
(patient_id,identifier,identifier_type,creator,date_created,location_id,voided)
VALUES (#{patient_id},"#{occupation}",3,1,'#{date_created.to_date}',#{current_location.id},#{voided});
EOF
end

#_______________________________________________________________________________________________________

#HIV 1st visit
    if rec.PermissionToTrace  
      ans = "Yes" if rec.PermissionToTrace == 1
      ans = "No" if rec.PermissionToTrace == 0
      ans = "Unknown" if ans.blank?
     
      value_coded = yes.id if ans == "Yes"
      value_coded = no.id if ans == "No"
      value_coded = unknown.id if ans == "Unknown"

      encounter_name = Encounter.new
      encounter_name.patient_id = patient_id
      encounter_name.type = hiv_first_visit_encounter
      encounter_name.encounter_datetime = date_created
      encounter_name.save 

      observation = Observation.new
      observation.patient_id = patient_id
      observation.encounter_id = encounter_name.id
      observation.concept = Concept.find_by_name("Agrees to followup")
      observation.value_coded = value_coded
      observation.obs_datetime = date_created
      observation.save
    end  

    if rec.Pregnant == 1
      if encounter_name.blank?
        encounter_name = Encounter.new
        encounter_name.patient_id = patient_id
        encounter_name.type = hiv_first_visit_encounter
        encounter_name.encounter_datetime = date_created
        encounter_name.save 
      end
      observation = Observation.new
      observation.encounter_id = encounter_name.id
      observation.patient_id = patient_id
      observation.concept = Concept.find_by_name("Pregnant when art was started")
      observation.value_coded = yes.id
      observation.obs_datetime = date_created
      observation.save
    end

    if rec.TransferIn
      if encounter_name.blank?
        encounter_name = Encounter.new
        encounter_name.patient_id = patient_id
        encounter_name.type = hiv_first_visit_encounter
        encounter_name.encounter_datetime = date_created
        encounter_name.save 
      end
      ans = "Yes" if rec.TransferIn == 1
      ans = "No" if rec.TransferIn == 0
      ans = "Unknown" if rec.TransferIn.blank?

      value_coded = yes.id if ans == "Yes"
      value_coded = no.id if ans == "No"
      value_coded = unknown.id if ans == "Unknown"
      ["Ever received ART","Ever registered at ART clinic"].each do |concept_name|
        observation = Observation.new
        observation.encounter_id = encounter_name.id
        observation.patient_id = patient_id
        observation.concept = Concept.find_by_name(concept_name)
        observation.value_coded = value_coded
        observation.obs_datetime = date_created
        observation.save
      end

      if ans == "Yes"
        location_id = rec.TransferFrom 
        location_name = rec.TransferFromSpecify
        observation = Observation.new
        observation.encounter_id = encounter_name.id
        observation.patient_id = patient_id
        observation.concept = Concept.find_by_name("Site transferred from")
        observation.value_coded = unknown.id
        if location_id
          observation.value_text = TableList.location_name(location_id)
        elsif location_name
          observation.value_text = location_name
        end  
        observation.obs_datetime = date_created
        observation.save
      end
    end

#HIV reception
    encounter_name = nil
    unless encounter_name.blank?
      encounter_name = Encounter.new
      encounter_name.patient_id = patient_id
      encounter_name.type = hiv_reception_encounter
      encounter_name.encounter_datetime = date_created
      encounter_name.save 

      observation = Observation.new
      observation.encounter_id = encounter_name.id
      observation.patient_id = patient_id
      observation.concept = Concept.find_by_name("Patient present")
      observation.value_coded = yes.id
      observation.obs_datetime = date_created
      observation.save
    end

#Height/Weight
    encounter_name = nil
    if rec.InitialWeight or rec.InitialHeight  
      encounter_name = Encounter.new
      encounter_name.patient_id = patient_id
      encounter_name.type = height_weight_encounter
      encounter_name.encounter_datetime = date_created
      encounter_name.save 
      ["Weight","Height"].each do |concept_name|
        value_numeric = rec.InitialWeight if concept_name == "Weight"
        value_numeric = rec.InitialHeight if concept_name == "Height"
        next if value_numeric.blank?
        observation = Observation.new
        observation.encounter_id = encounter_name.id
        observation.patient_id = patient_id
        observation.concept = Concept.find_by_name(concept_name)
        observation.value_numeric = value_numeric
        observation.obs_datetime = date_created
        observation.save
      end  
    end

#HIV staging
    encounter_name = nil
    if rec.BaselineCD4
      encounter_name = Encounter.new
      encounter_name.patient_id = patient_id
      encounter_name.type = hiv_staging_encounter
      encounter_name.encounter_datetime = date_created
      encounter_name.save 
      ["CD4 count","CD4 test date"].each do |concept_name|
        value_numeric = rec.BaselineCD4 if concept_name == "CD4 count"
        value_numeric = rec.BaselineCD4Date if concept_name == "CD4 test date"
        next if value_numeric.blank?
        observation = Observation.new
        observation.encounter_id = encounter_name.id
        observation.patient_id = patient_id
        observation.concept = Concept.find_by_name(concept_name)
        if concept_name == "CD4 count"
         observation.value_numeric = value_numeric
        else
         observation.value_datetime = value_numeric
        end   
        observation.obs_datetime = date_created
        observation.save
      end
    end  

    hiv_related_illness = TableHivRelatedIllness.get_all_patient_illness(patient_id)
    unless hiv_related_illness.blank?
      if encounter_name.blank?
        encounter_name = Encounter.new
        encounter_name.patient_id = patient_id
        encounter_name.type = hiv_staging_encounter
        encounter_name.encounter_datetime = date_created
        encounter_name.save 
      end 
      hiv_related_illness.each do |illness|
        concept = TableList.hiv_related_illness(illness.HIVRelatedIllness)
        next if concept.blank?
        observation = Observation.new
        observation.encounter_id = encounter_name.id
        observation.patient_id = patient_id
        observation.concept = concept.id
        observation.value_coded = yes.id
        observation.obs_datetime = date_created
        observation.save
      end rescue []
    end



#ART visit
    encounter_name = nil
    art_visit_data = TableVisit.art_visits(patient_id)
    patient = Patient.find(patient_id) ; location_id = Location.current_location.id
    art_visit_data.each do |visit_date,obs|
      prescribe_recommended_dosage = 3 if obs.treatment_change
      side_eff_ids = Concept.find(:all,:conditions =>["name IN (?)",obs.side_eff]).map{|eff|eff.concept_id} rescue nil
      cpt = 3 if obs.cpt_time_period
      pregnant = 2 if gender == "Female" 
      continue_treatment = 3
      prescribe_this_visit = obs.treatment_change  ? 3 : 4
      prescribe_period = obs.arv_supply || obs.cpt_time_period
      tablets = {}
      obs.total_pills_left.each do |pills|
        drug_id = pills.to_s.split(":")[0] ; pill_count = pills.to_s.split(":")[1]
        tablets["#{drug_id}"] = {"at_clinic" =>"#{pill_count}"}
      end unless obs.total_pills_left.blank? 

      observation = {"observation" => {"select:466"=> obs.side_eff,"select:509"=>"2","select:367"=>"3","select:368"=> prescribe_recommended_dosage,
      "select:446"=> side_eff_ids, "select:358"=>cpt,"select:447"=>side_eff_ids,"select:328"=>pregnant,"select:372"=> continue_treatment,
      "select:406"=>prescribe_this_visit,"alpha:345"=> prescribe_period, "location:389"=>"","select:18"=>obs.treatment_change,
      "select:388"=>"3","select:366"=>"4"}}

      encounter_datetime = visit_date.to_time ; encounter_type = 2
      Encounter.create(patient,observation,encounter_datetime,location_id,encounter_type,tablets)
    end unless art_visit_data.blank?

#Give drugs "Dispensed drugs"
    art_visit_data.each do |visit_date,obs|
      prescribe_period = obs.arv_supply || obs.cpt_time_period
      drug_dispensed =  obs.drug_dispensed
      next if prescribe_period.blank?
      next if drug_dispensed.blank?
      self.drug_dispense(patient,drug_dispensed,prescribe_period,visit_date.to_date)

      puts "DISPENSED DRUGS -------------------"
    end unless art_visit_data.blank?


    
#Update outcome
    all_outcomes = TableOutcome.all_outcomes(patient_id)
    all_outcomes.each do |outcome|
      outcome_date = outcome.split(",")[0].delete("Outcome date:").to_date rescue nil
      out_come = outcome.split(",")[1].gsub("Outcome:","") rescue nil
      reason = outcome.split(",")[2].gsub("Reason:","").strip rescue nil

      if out_come.match("TRANSFERRED") and reason
        out_come = "Transfer Out(With Transfer Note)"
      elsif out_come.match("TRANSFERRED") 
        out_come = "Transfer Out(Without Transfer Note)"
      elsif out_come.match("DIED") 
        out_come = "Died"
      elsif out_come.match("STOPPED") 
        out_come = "ART Stop"
      end
      self.set_outcome(patient_id,out_come,outcome_date,reason)
      puts "UPDATED OUTCOME <<<<<<<<<<<<<"
    end unless all_outcomes.blank?

#_______________________________________________________________________________________________________

      puts "created patient: patient_id: #{patient_id} name: #{given_name} #{family_name} >>>>>"
      count+=1

    end


#............................................................
#Guardian data
   self.find(:all,:conditions =>["GuardianName IS NOT NULL AND Name IS NOT NULL"]).each do |rec|
     date_created = rec.RegDate.to_time rescue Time.now()
     patient_id = rec.PatientID

     guardian_given_name = rec.GuardianName.split(' ')[0].gsub("//","").gsub("\\","") rescue nil
     guardian_family_name = rec.GuardianName.split(' ')[1].gsub("//","").gsub("\\","") rescue guardian_given_name
     guardian_gender = rec.GuardianGender
     sex = guardian_gender.to_i rescue nil
     gender = sex == 1 ? "Male" : "Female"
     birthdate = "01-07-#{date_created.year - rec.GuardianAge.to_i}".to_date rescue nil
     phone_number = rec.GuardianPhone.gsub(/ /,'') rescue nil
     city_village = rec.GuardianLocation.gsub("//","").gsub("\\","") rescue nil
     physical_address = rec.GuardianLocationSpecify.gsub("//","").gsub("\\","") rescue nil


     unless guardian_family_name.blank?   
       patient_found = false
       guardian_id = 1
       while patient_found == false do
         guardian = Patient.find(guardian_id).patient_id rescue nil
         patient_found = true if guardian.blank?
         break if patient_found
         guardian_id+=1
       end

       guardian_date_created = "#{date_created.to_date.to_s} #{Time.now.strftime("%H:%M:%S")}"
ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient
(patient_id,gender,birthdate,birthdate_estimated,creator,date_created,voided)
VALUES (#{guardian_id},'#{gender}','#{birthdate}',1,1,'#{guardian_date_created}',0);
EOF

      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_name
(patient_id,given_name,family_name,creator,date_created,voided)
VALUES (#{guardian_id},"#{guardian_given_name}","#{guardian_family_name}",1,'#{date_created.to_date}',0);
EOF

if city_village
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_address
(patient_id,city_village,creator,date_created,voided)
VALUES (#{guardian_id},"#{city_village}",1,'#{date_created.to_date}',0);
EOF
end

if physical_address
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_identifier
(patient_id,identifier,identifier_type,creator,date_created,location_id,voided)
VALUES (#{guardian_id},"#{physical_address}",6,1,'#{date_created.to_date}',#{current_location.id},0);
EOF
end

if phone_number
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_identifier
(patient_id,identifier,identifier_type,creator,date_created,location_id,voided)
VALUES (#{guardian_id},"#{phone_number}",11,1,'#{date_created.to_date}',#{current_location.id},0);
EOF
end

   
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO relationship
(person_id,relationship,relative_id,creator,date_created,voided)
VALUES (#{patient_id},11,#{guardian_id},1,'#{date_created.to_date}',0);
EOF

      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO person (patient_id) VALUES (#{guardian_id});
EOF

      puts "created guardian: guardian_id: #{guardian_id} name: #{guardian_given_name} #{guardian_family_name} <<<<<<<<<<"
      count2+=1
    end
#............................................................
  end

  puts ""
  puts ""
  puts ""
  puts ">>>>>>>>>>>>> done:"
  puts "created #{count} patient(s)"
  puts ""
  puts ""
  puts ""
  puts "created #{count2} Guardian(s)"
 end 
 
 def self.set_outcome(patient_id,outcome,date,reason=nil)
   patient = Patient.find(patient_id)
   return if outcome.nil? || date.nil?
    encounter = patient.encounters.find_first_by_type_name("Update outcome")
    if encounter.blank?
      encounter = Encounter.new
      encounter.patient_id = patient_id
      encounter.type = EncounterType.find_by_name("Update outcome")
      encounter.encounter_datetime = date
      encounter.provider_id = User.current_user.id
      encounter.save
    end

    obs = Observation.new
    obs.encounter = encounter
    obs.patient_id = patient_id 
    obs.concept = Concept.find_by_name("Outcome")
    obs.value_coded = Concept.find_by_name(outcome).id
    obs.obs_datetime = date
    obs.value_text = reason if outcome.match("Transfer")  and reason
    obs.save
    if outcome == "Died"
      patient.death_date = date
      patient.save
    end
  end

  def self.tb_visits
    tb_visits = TableTb.all_tb_visits

    tb_reception = EncounterType.find_by_name("TB Reception")
    tb_visit= EncounterType.find_by_name("TB Visit")
    tb_outcome = Concept.find_by_name("Outcome")
    start_treatment_date = Concept.find_by_name("TB start treatment date")
    end_treatment_date = Concept.find_by_name("TB end treatment date")
    tb_regimen = Concept.find_by_name("TB Regimen")
    tb_sputum_count = Concept.find_by_name("TB sputum count")
    yes = Concept.find_by_name("Yes")
    tb_treatment_id = Concept.find_by_name("TB treatment ID")
    patient_present = Concept.find_by_name("Patient present")
    art_status = Concept.find_by_name("ART status")

    tb_visits.each do |tb_id,visit|
      date = visit.CreatedOn.to_date rescue Time.now()
      patient = Patient.find(visit.PatientID) rescue nil
      next if patient.blank?
      encounter = Encounter.new
      encounter.patient_id = patient.id
      encounter.type = tb_reception
      encounter.encounter_datetime = date
      encounter.provider_id = User.current_user.id
      encounter.save

      obs = Observation.new
      obs.encounter = encounter
      obs.patient_id = patient.id 
      obs.concept = patient_present
      obs.value_coded = yes
      obs.obs_datetime = date
      obs.save

      encounter = Encounter.new
      encounter.patient_id = patient.id
      encounter.type = tb_visit
      encounter.encounter_datetime = date
      encounter.provider_id = User.current_user.id
      encounter.save

      obs = Observation.new
      obs.encounter = encounter
      obs.patient_id = patient.id 
      obs.concept = tb_treatment_id
      obs.value_text = tb_id
      obs.obs_datetime = date
      obs.save

      if visit.outcome
        obs = Observation.new
        obs.encounter = encounter
        obs.patient_id = patient.id 
        obs.concept = tb_outcome
        obs.value_coded = visit.outcome.id
        obs.obs_datetime = date
        obs.save
      end  

      if visit.start_date
        obs = Observation.new
        obs.encounter = encounter
        obs.patient_id = patient.id 
        obs.concept = start_treatment_date 
        obs.value_datetime = visit.start_date.to_date rescue nil
        obs.obs_datetime = date
        obs.save
      end  

      if visit.end_date
        obs = Observation.new
        obs.encounter = encounter
        obs.patient_id = patient.id 
        obs.concept = end_treatment_date 
        obs.value_datetime = visit.end_date.to_date rescue nil
        obs.obs_datetime = date
        obs.save
      end  

      if visit.art_status
        obs = Observation.new
        obs.encounter = encounter
        obs.patient_id = patient.id 
        obs.concept = art_status
        obs.value_text = TableList.art_status(visit.art_status)
        obs.obs_datetime = date
        obs.save
      end
        
      if visit.regimen
        obs = Observation.new
        obs.encounter = encounter
        obs.patient_id = patient.id 
        obs.concept = tb_regimen
        obs.value_text = TableList.tb_regimen(visit.regimen)
        obs.obs_datetime = date
        obs.save
      end
        
      if visit.sputum_count
        sputum_count = 0 
        visit.sputum_count.map{|s|sputum_count+=s.split(':')[1].to_i}
        obs = Observation.new
        obs.encounter = encounter
        obs.patient_id = patient.id 
        obs.concept = tb_sputum_count
        obs.value_numeric = sputum_count
        obs.obs_datetime = date
        obs.save
      end
        
    end unless tb_visits.blank?

  end
  
  def self.drug_dispense(patient,drugs,peroid,date)
    return if peroid.blank?
    encounter = Encounter.new()
    encounter.encounter_type = EncounterType.find_by_name("Give drugs")
    encounter.patient_id = patient.id
    encounter.encounter_datetime = date
    encounter.provider_id = User.current_user.id
    encounter.save

    order_type = OrderType.find_by_name("Give drugs")

    drugs.each{|drug|
      quantity = 60
      quantity = 15 if peroid.match("week")
      number_of_packs = self.number_of_packs(peroid)
      tablets_per_pack = quantity/number_of_packs
      order = Order.new
      order.order_type = order_type
      order.orderer = User.current_user.id
      order.encounter = encounter
      order.save
      1.upto(number_of_packs){ |pack_index|
        drug_order = DrugOrder.new
        drug_order.order = order
        drug_order.drug_inventory_id = drug.drug_id
        drug_order.quantity = tablets_per_pack
        drug_order.save
      }
    }
  end

  def self.number_of_packs(peroid)
    return 1 if peroid.match("week")
    return peroid.sub("months","").strip.to_i
  end

  def self.hospital_visit
    visits = TableHospitalization.all_hospital_visit

    general_reception = EncounterType.find_by_name("General Reception")
    outpatient_diagnosis = EncounterType.find_by_name("Outpatient diagnosis")
    yes = Concept.find_by_name("Yes")
    patient_present = Concept.find_by_name("Patient present")
    primary_diagnosis = Concept.find_by_name("Primary diagnosis")
    secondary_diagnosis = Concept.find_by_name("Secondary diagnosis")
    same_visit = {}    
 
    visits.each do |visit|  
      date = visit.HospitalDate.to_date rescue nil
      patient = Patient.find(visit.PatientID) rescue nil
      next if patient.blank?
      next if date.blank?
      sec_diagnosis = false
      sec_diagnosis = true unless same_visit["#{patient.id}:#{date}"].blank?
      encounter = Encounter.new
      encounter.patient_id = patient.id
      encounter.type = general_reception
      encounter.encounter_datetime = date
      encounter.provider_id = User.current_user.id
      encounter.save

      obs = Observation.new
      obs.encounter = encounter
      obs.patient_id = patient.id 
      obs.concept = patient_present
      obs.value_coded = yes
      obs.obs_datetime = date
      obs.save

      if visit.HospitalDiagnosis
        encounter = Encounter.new
        encounter.patient_id = patient.id
        encounter.type = outpatient_diagnosis
        encounter.encounter_datetime = date
        encounter.provider_id = User.current_user.id
        encounter.save

        diagnosis = sec_diagnosis ? secondary_diagnosis : primary_diagnosis
        obs = Observation.new
        obs.encounter = encounter
        obs.patient_id = patient.id 
        obs.concept = diagnosis
        obs.value_text = visit.HospitalDiagnosis
        obs.obs_datetime = date
        obs.save
        same_visit["#{patient.id}:#{date}"] = visit.HospitalDiagnosis
      end

    end unless visits.blank?
  end

end
