class TableMain < OpenMRS
  set_table_name "tblmain"
   
  def self.create_patients
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
      if physical_address == "*** SEE NOTES ***" || physical_address.blank?
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
(patient_id,identifier,identifier_type,creator,date_created,voided)
VALUES (#{patient_id},"#{physical_address}",6,1,'#{date_created.to_date}',#{voided});
EOF
end

if ta
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_identifier
(patient_id,identifier,identifier_type,creator,date_created,voided)
VALUES (#{patient_id},"#{ta}",9,1,'#{date_created.to_date}',#{voided});
EOF
end

if phone_number
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_identifier
(patient_id,identifier,identifier_type,creator,date_created,voided)
VALUES (#{patient_id},"#{phone_number}",11,1,'#{date_created.to_date}',#{voided});
EOF
end

      puts "created patient: patient_id: #{patient_id} name: #{given_name} #{family_name}>>>"
      count+=1
    end


#Guardian data
   self.find(:all,:conditions =>["GuardianName IS NOT NULL"]).each do |rec|
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
(patient_id,identifier,identifier_type,creator,date_created,voided)
VALUES (#{guardian_id},"#{physical_address}",6,1,'#{date_created.to_date}',0);
EOF
end

if phone_number
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_identifier
(patient_id,identifier,identifier_type,creator,date_created,voided)
VALUES (#{guardian_id},"#{phone_number}",11,1,'#{date_created.to_date}',0);
EOF
end

   
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO relationship
(person_id,relationship,relative_id,creator,date_created,voided)
VALUES (#{patient_id},11,#{guardian_id},1,'#{date_created.to_date}',0);
EOF

      puts "created guardian: guardian_id: #{guardian_id} name: #{guardian_given_name} #{guardian_family_name}__________"
      count2+=1
    end
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
