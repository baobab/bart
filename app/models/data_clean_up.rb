class DataCleanUp < OpenMRS
  set_table_name "tblMain"
   
  def self.migrate_data
    current_location = Location.current_location
    User.current_user = User.find(1)
    hiv_staging_encounter = EncounterType.find_by_name("HIV Staging")
    hiv_first_visit_encounter = EncounterType.find_by_name("HIV First visit")
    hiv_reception_encounter = EncounterType.find_by_name("HIV Reception")
    height_weight_encounter = EncounterType.find_by_name("Height/Weight")
    art_visit_encounter = EncounterType.find_by_name("ART Visit")
    give_drugs_encounter = EncounterType.find_by_name("Give drugs")
    relationship_type = RelationshipType.find_by_name("Other")
    previous_arv_number = PatientIdentifierType.find_by_name("Previous ARV number")
    nearest_clinic = PatientIdentifierType.find_by_name("Nearest Health Clinic")
    htc = EncounterType.find_by_name("HTC")
    location = Concept.find_by_name("Location")

    pregnant_when_art_was_started_id = Concept.find_by_name("Pregnant when art was started").id
    site_transferred_from_id = Concept.find_by_name("Site transferred from").id
    patient_present_id = Concept.find_by_name("Patient present").id
    referred_by_pmtct = Concept.find_by_name("Referred by PMTCT")
    hiv = Concept.find_by_name("HIV")

    yes = Concept.find_by_name("Yes")
    no = Concept.find_by_name("No")
    unknown = Concept.find_by_name("Unknown")


    count = 0
    count2 = 0
    patients = DataCleanUp.find(:all,:conditions => ["Name IS NOT NULL AND PatientID IS NOT NULL"],:order =>"PatientID ASC")
    patients.each do |rec|
      patient_id = rec.PatientID 
      empt = Patient.find(patient_id) rescue nil
      next if empt.blank?

      prev_arv_number = rec.PrevARVID
      htc_result = rec.HTCResult
      htc_location = rec.HTCLocation
      htc_date = rec.HTCDate
      nearest_center = rec.NearestHlthCtr 

      unless prev_arv_number.blank?
        arv_number = prev_arv_number.match(/[0-9](.*)/i)[0] rescue nil
        unless arv_number.blank?
          identifier = PatientIdentifier.new()
          identifier.identifier = "#{prev_arv_number.match(/(.*)[A-Z]/i)[0].upcase rescue 'ZCH'} #{arv_number.to_i}"
          identifier.identifier_type = previous_arv_number.id
          identifier.patient_id = patient_id
          identifier.save
        end rescue nil
      end

      unless nearest_center.blank?
        identifier = PatientIdentifier.new()
        identifier.identifier = nearest_center
        identifier.identifier_type = nearest_clinic.id
        identifier.patient_id = patient_id
        identifier.save
      end

      unless htc_result.blank?
       encounter = Encounter.new()
       encounter.encounter_type = htc.id
       encounter.patient_id = patient_id
       encounter.encounter_datetime = htc_date.to_date rescue Time.now()
       encounter.save

       obs = Observation.new()
       obs.encounter_id = encounter.id
       obs.obs_datetime = encounter.encounter_datetime
       obs.concept_id = hiv.id
       obs.patient_id = patient_id
       obs.value_coded = yes.id if htc_result == 1
       obs.value_coded = no.id if htc_result == 0
       obs.save
      
       unless htc_location.blank?
         obs = Observation.new()
         obs.encounter_id = encounter.id
         obs.obs_datetime = encounter.encounter_datetime
         obs.concept_id = hiv.id
         obs.value_text = htc_location
         location_id = Location.find(:first,:conditions =>["name LIKE '%#{htc_location}%'"],
          :order => "location_id ASC").location_id rescue nil
         obs.value_coded = location_id unless location_id.blank?
         obs.patient_id = patient_id
         obs.save
       end 
      end

      unless rec.ARTReason.blank?
        puts "Migrating WHO satge"
        self.who_stage(patient_id,rec.ARTReason)
      end

      physical_address = rec.Village.gsub("//","").gsub("\\","").strip rescue nil
      if physical_address == "*** SEE NOTES ***"
        rec.DemographicNotes.split(";").each do |r|
          identifier = r.split(":")[1].strip rescue nil
          type = r.split(":")[0].strip rescue nil
          if type == "Village" and identifier 
            puts "Address - Demographic notes: #{identifier}"
      ActiveRecord::Base.connection.execute <<EOF
DELETE FROM patient_address
WHERE patient_id = #{patient_id};
EOF
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_address
(patient_id,city_village,creator,date_created,voided)
VALUES (#{patient_id},"#{identifier}",1,'#{Date.today.to_date}',0);
EOF
          end
        end rescue nil
      end

      traditional_authority = rec.TraditionalAuthority.gsub("//","").gsub("\\","").strip rescue nil
      if traditional_authority == "*** SEE NOTES ***"
        rec.DemographicNotes.split(";").each do |r|
          identifier = r.split(":")[1].strip rescue nil
          type = r.split(":")[0].strip rescue nil
          if type == "TA" and identifier
            puts "TA - Demographic notes: #{identifier}"
      ActiveRecord::Base.connection.execute <<EOF
DELETE FROM patient_identifier 
WHERE patient_id = #{patient_id} AND identifier_type = 9;
EOF
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_identifier
(patient_id,identifier,identifier_type,creator,date_created,location_id,voided)
VALUES (#{patient_id},'#{identifier}',9,1,'#{Date.today.to_date}',689,0);
EOF
          end rescue nil
        end rescue nil
      end


      loc = rec.PatientLocation.gsub("//","").gsub("\\","") rescue nil
      unless loc.blank?
       puts "Phy location - Demographic notes: #{loc}"
      ActiveRecord::Base.connection.execute <<EOF
DELETE FROM patient_identifier 
WHERE patient_id = #{patient_id} AND identifier_type = 6;
EOF
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_identifier
(patient_id,identifier,identifier_type,creator,date_created,location_id,voided)
VALUES (#{patient_id},"#{loc}",6,1,'#{Date.today.to_date}',689,0);
EOF
      end rescue nil


      puts ""
      puts "record number: #{count+=1}::::::::::patient id -  #{patient_id}"
    end
    
    self.migrate_tb_data
  end 

  def self.migrate_tb_data
    tb_visits = TableTb.all_tb_visits
    return if tb_visits.blank?
    tb_reception = EncounterType.find_by_name("TB Reception")
    tb_visit= EncounterType.find_by_name("TB Visit")
    tb_outcome = Concept.find_by_name("Outcome").id
    start_treatment_date = Concept.find_by_name("TB start treatment date").id
    end_treatment_date = Concept.find_by_name("TB end treatment date").id
    tb_regimen = Concept.find_by_name("TB Regimen").id
    tb_sputum_count = Concept.find_by_name("TB sputum count").id
    yes = Concept.find_by_name("Yes").id
    tb_treatment_id = PatientIdentifierType.find_by_name("TB treatment ID").id
    patient_present = Concept.find_by_name("Patient present").id
    art_status = Concept.find_by_name("ART status").id
    tb_episode_type = Concept.find_by_name("TB Episode type").id
    cpt = Concept.find_by_name("Cotrimoxazole").id



    encounter_ids = Encounter.find(:all,:conditions =>["creator = 1 AND encounter_type = 20"]).map{|e|e.encounter_id} rescue nil
    unless encounter_ids.blank?
ActiveRecord::Base.connection.execute <<EOF
DELETE FROM patient_identifier
WHERE creator = 1 AND identifier_type = 21;
EOF

ActiveRecord::Base.connection.execute <<EOF
DELETE FROM obs
WHERE creator = 1 AND encounter_id IN (#{encounter_ids});
EOF

ActiveRecord::Base.connection.execute <<EOF
DELETE FROM encounter
WHERE creator = 1 AND encounter_type IN (#{encounter_ids});
EOF
    end

    tb_visits.each do |visits|
        next if visits.TbTreatStart.blank?
        patient = Patient.find(visits.PatientID) rescue nil
        next if patient.blank?
        patient_tb_visits = TableVisit.tb_visits(visits.PatientID)
        next if patient_tb_visits.blank?
=begin       
        if patient.id 
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_program
(patient_id,program_id,creator,date_created,voided)
VALUES (#{patient.id},2,1,'#{Date.today.to_s}',1);
EOF
        end rescue nil
=end
        patient_tb_visits.sort.each do |key,data|
          puts "Creating TB encounter for patient ID: #{visits.PatientID} "

          if key.split("::")[0]
            patient_identifier = PatientIdentifier.new
            patient_identifier.identifier_type = tb_treatment_id
            patient_identifier.patient_id = visits.PatientID
            prefix = key.split("::")[0].match(/(.*)[A-Z]/i)[0].upcase rescue 'ZA' 
            number = key.split("::")[0].match(/[0-9](.*)/i)[0] rescue nil
            patient_identifier.identifier = "#{prefix} #{number}"
            patient_identifier.save
          end rescue nil

          encounter = Encounter.new
          encounter.patient_id = visits.PatientID
          encounter.type = tb_reception
          encounter.encounter_datetime = key.split("::")[1].to_date
          encounter.provider_id = User.current_user.id
          encounter.save

          obs = Observation.new
          obs.encounter = encounter
          obs.patient_id = visits.PatientID
          obs.concept_id = patient_present
          obs.value_coded = yes
          obs.obs_datetime = key.split("::")[1].to_date
          obs.save

          encounter = Encounter.new
          encounter.patient_id = visits.PatientID
          encounter.type = tb_visit
          encounter.encounter_datetime = key.split("::")[1].to_date
          encounter.provider_id = User.current_user.id
          encounter.save

          if data.outcome
            obs = Observation.new
            obs.encounter = encounter
            obs.patient_id = visits.PatientID
            obs.concept_id = tb_outcome
            obs.value_coded = data.outcome.id
            obs.obs_datetime = key.split("::")[1].to_date
            obs.save
          end  

          if data.start_date
            obs = Observation.new
            obs.encounter = encounter
            obs.patient_id = visits.PatientID
            obs.concept_id = start_treatment_date 
            obs.value_datetime = data.start_date.to_date rescue nil
            obs.obs_datetime = key.split("::")[1].to_date
            obs.save
          end  

          if data.end_date
            obs = Observation.new
            obs.encounter = encounter
            obs.patient_id = visits.PatientID
            obs.concept_id = end_treatment_date 
            obs.value_datetime = data.end_date.to_date rescue nil
            obs.obs_datetime = key.split("::")[1].to_date
            obs.save
          end  

          if data.art_status
            obs = Observation.new
            obs.encounter = encounter
            obs.patient_id = visits.PatientID
            obs.concept_id = art_status
            obs.value_coded = Concept.find_by_name(data.art_status).id
            obs.obs_datetime = key.split("::")[1].to_date
            obs.save
          end
          
          if data.regimen
            obs = Observation.new
            obs.encounter = encounter
            obs.patient_id = visits.PatientID
            obs.concept_id = tb_regimen
            obs.value_coded = Concept.find_by_name(data.regimen).id 
            obs.obs_datetime = key.split("::")[1].to_date
            obs.save
          end
            
          if data.sputum_count
            obs = Observation.new
            obs.encounter = encounter
            obs.patient_id = visits.PatientID
            obs.concept_id = tb_sputum_count
            obs.value_numeric = data.sputum_count
            obs.obs_datetime = key.split("::")[1].to_date
            obs.save
          end

          if data.tb_type
            obs = Observation.new
            obs.encounter = encounter
            obs.patient_id = visits.PatientID
            obs.concept_id = data.tb_type.id
            obs.value_coded = yes
            obs.value_text = data.eptb_type unless data.eptb_type.blank?
            obs.obs_datetime = key.split("::")[1].to_date
            obs.save
          end

          if data.episode_type
            obs = Observation.new
            obs.encounter = encounter
            obs.patient_id = visits.PatientID
            obs.concept_id = tb_episode_type
            obs.value_coded = data.episode_type.id
            obs.obs_datetime = key.split("::")[1].to_date
            obs.save
          end
         
          if data.cpt
            obs = Observation.new
            obs.encounter = encounter
            obs.patient_id = visits.PatientID
            obs.concept_id = cpt
            obs.value_coded = yes
            obs.obs_datetime = key.split("::")[1].to_date
            obs.save
          end
       end 

       puts "Created TB encounter: #{visits.PatientID}"  
    end unless tb_visits.blank?

  end


  def self.who_stage(patient_id,stage)
    if stage
      ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_identifier
(patient_id,identifier,identifier_type,creator,date_created,location_id,voided)
VALUES (#{patient_id},#{stage},24,1,'#{Date.today.to_date}',689,0);
EOF
    end rescue nil
  end


end
