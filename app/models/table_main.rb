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
    if hiv_related_illness.blank?
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
      end
    end



#ART visit
    encounter_name = nil
    #art_visit_data = TableVisit.visits(patient_id)


    


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
(person_id,relationship,relative_id,creator,date_created,location_id,voided)
VALUES (#{patient_id},11,#{guardian_id},1,'#{date_created.to_date}',#{current_location.id},0);
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

end
