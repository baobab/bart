HIV_FIRST_ENCOUNTER_ID = EncounterType.find_by_name('HIV First visit').id
ART_VIST_ID = EncounterType.find_by_name('ART Visit').id
GIVE_DRUGS_ID = EncounterType.find_by_name('Give drugs').id
HIV_RECEPTION_ID = EncounterType.find_by_name('HIV Reception').id
HEIGHT_WEIGHT_ID = EncounterType.find_by_name('Height/Weight').id
UPDATE_OUTCOME_ID = EncounterType.find_by_name('Update outcome').id

DATE_OF_ART_INITIATION_ID = EncounterType.find_by_name('HIV First visit').id

  def update_encounter
    count = 0
    File.open(File.join("/home/ace/Desktop/MigratedTransIn.csv"), File::RDONLY).readlines[1..-1].each{|line|
      prescription = nil  
      data_row = line.chomp.split(";").collect{|text|text.gsub(/"/,"")} 
      patient_id =  data_row[0].to_i rescue nil
      registration_date = data_row[1].to_date rescue nil ; art_start_date = data_row[2].to_date rescue nil

      next if patient_id.blank? or registration_date.blank? or art_start_date.blank?


      #registration_date == 1st give drugs of ARVs
      #art_start_date == the min btwn registration_date and Date of art initiation ()

      patient_initial_visit_obs = Observation.find(:all,
                                                   :joins => "INNER JOIN encounter e USING (encounter_id)",    
                                                   :conditions => ["voided = 0 AND encounter_type = ? AND e.patient_id = ?",
                                                   HIV_FIRST_ENCOUNTER_ID,patient_id])
      
      create_new_obs = true

      (patient_initial_visit_obs || [] ).each do |obs|
        if obs.concept_id == DATE_OF_ART_INITIATION_ID
          o = Observation.find(obs.obs_id)
          o.value_datetime = art_start_date ; o.save
          create_new_obs = false
        end
      end

      if create_new_obs
        e = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ?",
            patient_id , HIV_FIRST_ENCOUNTER_ID])
        if e.blank?
          e = Encounter.new()
          e.encounter_type = HIV_FIRST_ENCOUNTER_ID
          e.patient_id = patient_id
          e.encounter_datetime = art_start_date
          e.save
        end
        obs = Observation.new()
        obs.patient_id = patient_id
        obs.value_datetime = art_start_date
        obs.concept_id = DATE_OF_ART_INITIATION_ID
        obs.encounter_id = e.id
        obs.obs_datetime = Time.now()
        obs.save
      end

      date_patient_got_arvs_first = Encounter.find(:first,
                                                   :joins => "INNER JOIN orders ON encounter.encounter_id = orders.encounter_id",
                                                   :conditions => ["voided = 0 AND encounter_type = ? AND encounter.patient_id = ?",
                                                   GIVE_DRUGS_ID,patient_id]).encounter_datetime.to_date rescue []
                                                   


      unless date_patient_got_arvs_first.blank?
        encounters = []
        encounters << Encounter.find(:first,:conditions => ["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient_id,HIV_RECEPTION_ID,date_patient_got_arvs_first]) 

        encounters << Encounter.find(:first,:conditions => ["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient_id,HEIGHT_WEIGHT_ID,date_patient_got_arvs_first])

        encounters << Encounter.find(:first,:conditions => ["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient_id,ART_VIST_ID,date_patient_got_arvs_first])

        encounters << Encounter.find(:first,:conditions => ["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient_id,HIV_FIRST_ENCOUNTER_ID,date_patient_got_arvs_first])

        encounters << Encounter.find(:first,:conditions => ["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient_id,UPDATE_OUTCOME_ID,date_patient_got_arvs_first])

        give_drugs = Encounter.find(:first,:conditions => ["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
                                   patient_id,GIVE_DRUGS_ID,date_patient_got_arvs_first])

        unless encounters.blank?
          (encounters.compact || []).each do |enc|
            (enc.observations || []).each do |ob|
              o = Observation.find(ob.obs_id)
              o.obs_datetime = registration_date ; o.save
            end
            encs = Encounter.find(enc.encounter_id)
            encs.encounter_datetime = registration_date ; encs.save
          end
        end

        if give_drugs
          (give_drugs.observations || []).each do |ob|
            o = Observation.find(ob.obs_id)
            o.obs_datetime = registration_date ; o.save
          end
          give_drugs.encounter_datetime = registration_date ; give_drugs.save
        end
      end

      puts "#{count+=1} >>>>>>>>>>>>> #{patient_id}"
    }
  end

  User.current_user = User.find(1)
  update_encounter
