CD4_CONCEPT_ID = Concept.find_by_name('CD4 Count').id
LOW_CONCEPT_ID = Concept.find_by_name('CD4 Count < 250').id
YES_CONCEPT_ID = Concept.find_by_name('Yes').id
NO_CONCEPT_ID  = Concept.find_by_name('No').id

  def update_obs
    count = 0
    
    File.open(File.join("/home/ace/Desktop/zch_staging_conditions.csv"), File::RDONLY).readlines[1..-1].each{|line|
      data_row = line.chomp.split(",").collect{|text|text.gsub(/"/,"")} 
      patient_id =  data_row[0] ; arv_number = data_row[1] ; cd4_count = data_row[2].to_f rescue nil
      conditions = []
      conditions <<  data_row[3].to_i unless data_row[3].blank?
      conditions <<  data_row[4].to_i unless data_row[4].blank?
      conditions <<  data_row[5].to_i unless data_row[5].blank?
      conditions <<  data_row[6].to_i unless data_row[6].blank?

      encounter = Encounter.find(:first,:conditions => ["encounter_type = 5 AND patient_id = ?",patient_id],
            :order => "encounter_datetime desc")
      obs = encounter.observations rescue nil
      next if encounter.blank?

      obs_cd4 = obs.find_by_concept_id(CD4_CONCEPT_ID) rescue []

      unless obs_cd4.blank?
        o = obs_cd4[0]
        if !(o.value_numeric == cd4_count) and cd4_count > 0
          o.void!('Value updated')
          o.save

          puts "---------  #{cd4_count}"
          new_o = Observation.new()
          new_o.concept_id = CD4_CONCEPT_ID
          new_o.encounter_id = encounter.id
          new_o.obs_datetime = encounter.encounter_datetime
          new_o.value_numeric = cd4_count
          new_o.patient_id = encounter.patient_id
          new_o.save

          if cd4_count < 250
            new_o = Observation.new()
            new_o.concept_id = LOW_CONCEPT_ID
            new_o.encounter_id = encounter.id
            new_o.obs_datetime = encounter.encounter_datetime
            new_o.value_coded = YES_CONCEPT_ID
            new_o.patient_id = encounter.patient_id
            new_o.save
          elsif cd4_count >= 250
            new_o = Observation.new()
            new_o.concept_id = LOW_CONCEPT_ID
            new_o.encounter_id = encounter.id
            new_o.obs_datetime = encounter.encounter_datetime
            new_o.value_coded = NO_CONCEPT_ID
            new_o.patient_id = encounter.patient_id
            new_o.save
          end
        end
      end

     conditions.compact.uniq.each do |stage|
      obs.each{|o|
        obs_cond = obs.find_by_concept_id(stage) 
        if obs_cond.blank?
          puts "create new staging obs"
          new_o = Observation.new()
          new_o.concept_id = stage
          new_o.encounter_id = encounter.id
          new_o.obs_datetime = encounter.encounter_datetime
          new_o.value_coded = YES_CONCEPT_ID
          new_o.patient_id = encounter.patient_id
          new_o.save
        end
      } 
     end
     puts ">>>>>>>>>>>>>>>>>>> #{count+=1}"
    }
  end
  User.current_user = User.find(1)
  update_obs
