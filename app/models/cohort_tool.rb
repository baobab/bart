class CohortTool < OpenMRS
  set_table_name "encounter"

  def self.adherence(quater="Q1 2009")
    date = self.cohort_date(quater)
     
    start_date = (date.to_s + " 00:00:00")
    end_date = date + 3.month - 1.day
    end_date = (end_date.to_s + " 23:59:59")

=begin    
    encounter_type = EncounterType.find_by_name("Give drugs").id
    encounters = self.find(:all,
                           :joins => "INNER JOIN obs ON obs.encounter_id = encounter.encounter_id AND obs.voided = 0",
                           :conditions => ["encounter_type=? AND encounter_datetime >=? AND encounter_datetime <=?",
                           encounter_type,start_date,end_date],
                           :group => "encounter.patient_id",:order => "encounter_datetime DESC")

    adherence = Hash.new(0)
    puts ">> #{Time.now()}"
    encounters.each{|encounter|
      adh = Patient.find(encounter.patient_id).adherence(encounter.encounter_datetime.to_date) 
      adh = "Not done" if adh.blank?
      adherence[adh]+=1
    }
    puts ">> #{Time.now()}"
    adherence
=end    
  end

  def self.cohort_date(quater)
    q = quater.split(" ").first
    year = quater.split(" ").last.to_i

    case q
      when "Q1"
        return Date.new(year,1,1)
      when "Q2"
        return Date.new(year,4,1)
      when "Q3"
        return Date.new(year,7,1)
      when "Q4"
        return Date.new(year,10,1)
    end
  end

  def self.visits_by_day(quater)
    date = self.cohort_date(quater)
    start_date = (date.to_s + " 00:00:00")
    end_date = date + 3.month - 1.day
    end_date = (end_date.to_s + " 23:59:59")
    encounter_ids = Array.new()
    encounter_ids << EncounterType.find_by_name("Barcode scan").id
    encounter_ids << EncounterType.find_by_name("TB Reception").id
    encounter_ids << EncounterType.find_by_name("General Reception").id
    encounter_ids << EncounterType.find_by_name("Move file from dormant to active").id
    encounter_ids << EncounterType.find_by_name("Update outcome").id

    visits_by_day = Hash.new(0)

    encounters = self.find(:all,
                           :joins => "INNER JOIN obs ON obs.encounter_id = encounter.encounter_id AND obs.voided = 0",
                           :conditions => ["encounter_type NOT IN (?) AND encounter_datetime >=? AND encounter_datetime <=?",
                           encounter_ids,start_date,end_date],
                           :group => "encounter.patient_id,DATE(encounter_datetime)",:order => "encounter_datetime ASC")

    encounters.each{|encounter|
      visits_by_day[encounter.encounter_datetime.strftime("%d-%b-%Y")]+=1
    }
    visits_by_day
  end


  def self.non_ligible_patients_in_cohort(quater,arv_number_range_start,arv_number_range_end)
    date = self.cohort_date(quater)
    start_date = (date.to_s + " 00:00:00")
    end_date = date + 3.month - 1.day
    end_date = (end_date.to_s + " 23:59:59")
    identifier_type = PatientIdentifierType.find_by_name("Arv national id").id

    pats = Patient.find(:all,
                         :joins => "INNER JOIN patient_identifier i on i.patient_id=patient.patient_id
                         INNER JOIN patient_start_dates s ON i.patient_id=s.patient_id",
                         :conditions => ["i.voided=0 and i.identifier_type = ? and s.start_date >= ?
                         and s.start_date <= ? and char_length(identifier) < ? OR char_length(identifier) > ?
                         OR i.identifier IS NULL",
                         identifier_type,start_date,end_date,arv_number_range_start,arv_number_range_end],
                         :group => "i.patient_id",:order => "char_length(identifier) ASC")
   
   patients = self.patients_to_show(pats)
  end

  def self.patients_to_show(pats)
    patients = Hash.new()
    pats.each{|patient|
      patients[patient.id]={"id" =>patient.id,"arv_number" => patient.arv_number,
                           "name" =>patient.name,"national_id" =>patient.national_id,
                           "gender" =>patient.sex,"age" =>patient.age,"birthdate" => patient.birthdate,
                           "start_date" => patient.date_started_art}
    }
   patients
  end

  def self.internal_consistency_checks(quater)
    date = self.cohort_date(quater)
    start_date = (date.to_s + " 00:00:00")
    end_date = date + 3.month - 1.day
    end_date = (end_date.to_s + " 23:59:59")
    patients = Hash.new()

    female_names=''
    male_names=''
   
    #possible female/male names
    ["female","male"].each{|gender|
      File.open(File.join(RAILS_ROOT, "public/list_of_possible_#{gender}_names.csv"), File::RDONLY).readlines[1..-1].each{|line|
        name = line.chomp.split(",").collect{|text|text.gsub(/"/,"")} 
        if gender == "male"      
          male_names+=" OR n.given_name = '#{name}'" unless male_names.blank?
          male_names+="n.given_name = '#{name}'" if male_names.blank?
        else
          female_names+=" OR n.given_name = '#{name}'" unless female_names.blank?
          female_names+="n.given_name = '#{name}'" if female_names.blank?
        end
      }
    }
    
    ["female","male"].each{|gender|
      case gender 
        when "female"
          patients[gender] = self.patients_with_possible_wrong_sex(male_names,start_date,end_date,"Female")
        when "male"
          patients[gender] = self.patients_with_possible_wrong_sex(female_names,start_date,end_date,"Male")
        end
    }
    
    patients["wrong_start_dates"] = self.patients_with_start_dates_less_than_first_give_drug_date(start_date,end_date)

    patients["pregnant_males"] = self.male_patients_with_pregnant_obs(start_date,end_date)

    patients["patients_with_no_height"] = self.patients_with_height_or_weight(start_date,end_date,"Height")

    patients["patients_with_no_weight"] = self.patients_with_height_or_weight(start_date,end_date,"Weight")

    patients["dead_patients_with_visits"] =  self.patients_with_dead_outcomes_but_still_on_art(start_date,end_date)

    patients["patients_who_moved_from_2nd_to_1st_line_drugs"] =  self.patients_who_moved_from_2nd_to_1st_line_drugs(start_date,end_date)

    patients
  end

  def self.patients_who_moved_from_2nd_to_1st_line_drugs(start_date,end_date)
    concept_id = Concept.find_by_name("Stavudine Lamivudine Nevirapine Regimen").id

    Patient.find_by_sql("SELECT * FROM patient inner join patient_historical_regimens r on r.patient_id=patient.patient_id
     WHERE r.regimen_concept_id != #{concept_id} AND (SELECT regimen_concept_id FROM patient_historical_regimens reg WHERE reg.patient_id = r.patient_id and reg.dispensed_date > r.dispensed_date ORDER BY dispensed_date LIMIT 1) = #{concept_id} AND r.dispensed_date >='#{start_date}' AND r.dispensed_date <= '#{end_date}' ORDER BY r.patient_id,r.dispensed_date")
  end

  def self.patients_with_dead_outcomes_but_still_on_art(start_date,end_date)
    dead_concept_id = Concept.find_by_name("Died").id
    concept_id = Concept.find_by_name("Outcome").id
    encounters_not_to_consider = []
    encounters_not_to_consider << EncounterType.find_by_name("Barcode scan").id
    encounters_not_to_consider << EncounterType.find_by_name("Update outcome").id

    Patient.find(:all,
                 :joins => "INNER JOIN encounter ON encounter.patient_id=patient.patient_id
                 INNER JOIN patient_historical_outcomes outcome ON outcome.patient_id=encounter.patient_id
                 INNER JOIN obs ON encounter.encounter_id=obs.encounter_id",
                 :conditions => ["encounter.encounter_type NOT IN (?) AND outcome.outcome_concept_id=? AND encounter.encounter_datetime >= ?
                 AND encounter.encounter_datetime <= ? AND (Date(outcome.outcome_date) < Date(encounter.encounter_datetime)) AND obs.voided=0",
                 encounters_not_to_consider,dead_concept_id,start_date,end_date],
                 :group => "encounter.patient_id,outcome.outcome_date",:order => "outcome.outcome_date DESC").uniq rescue nil
    
 
  end

  def self.patients_with_height_or_weight(start_date,end_date,concept_name)
    concept_id = Concept.find_by_name(concept_name).id
    patient_with_no_height_weight = Patient.find(:all,
                 :joins => "INNER JOIN patient_start_dates s ON patient.patient_id=s.patient_id
                 INNER JOIN obs ON obs.patient_id=patient.patient_id",
                 :conditions => ["obs.voided=0 AND obs.concept_id=? AND s.start_date >= ?
                 AND s.start_date <= ? AND obs.value_numeric IS NULL AND obs.value_coded IS NULL",
                 concept_id,start_date,end_date],:group => "obs.patient_id")

    return [] if patient_with_no_height_weight.blank?
    patient_ids = patient_with_no_height_weight.collect{|pat|pat.id}

    patient_with_height_weight = Patient.find(:all,
                 :joins => "INNER JOIN obs ON obs.patient_id=patient.patient_id",
                 :conditions => ["obs.voided=0 AND obs.concept_id=? 
                 AND obs.value_numeric IS NOT NULL AND obs.patient_id IN (?)",
                 concept_id,patient_ids],:group => "obs.patient_id")

    (patient_with_no_height_weight - patient_with_height_weight)
  end

  def self.patients_with_possible_wrong_sex(additional_sql,start_date,end_date,sex)
    Patient.find(:all,
                 :joins => "INNER JOIN patient_start_dates s ON patient.patient_id=s.patient_id
                 INNER JOIN obs ON obs.patient_id=patient.patient_id
                 INNER JOIN patient_name n ON patient.patient_id=n.patient_id",
                 :conditions => ["n.voided=0 AND obs.voided=0 and s.start_date >= ?
                 and s.start_date <= ? AND patient.gender=? AND (#{additional_sql})",
                 start_date,end_date,sex],:group => "patient.patient_id").uniq rescue nil
  end

  def self.patients_with_start_dates_less_than_first_give_drug_date(start_date,end_date)
    encounter_type = EncounterType.find_by_name("Give drugs").id
    Patient.find(:all,
                 :joins => "INNER JOIN patient_start_dates s ON patient.patient_id=s.patient_id
                 INNER JOIN obs ON obs.patient_id=patient.patient_id
                 INNER JOIN encounter e ON obs.encounter_id=e.encounter_id",
                 :conditions => ["obs.voided=0 and s.start_date >= ?
                 and s.start_date <= ? AND e.encounter_type=? AND (Date(s.start_date) > Date(e.encounter_datetime))",
                 start_date,end_date,encounter_type],
                 :group => "e.patient_id",:order =>"e.encounter_datetime ASC").uniq rescue nil
  end

  def self.male_patients_with_pregnant_obs(start_date,end_date)
    concept_id = Concept.find_by_name("Pregnant").id
    Patient.find(:all,
                 :joins => "INNER JOIN obs ON patient.patient_id=obs.patient_id
                 INNER JOIN patient_start_dates s ON patient.patient_id=s.patient_id",
                 :conditions => ["obs.voided=0 and s.start_date >= ?
                 and s.start_date <= ? AND obs.concept_id=? AND patient.gender='Male'",
                 start_date,end_date,concept_id],
                 :group => "obs.patient_id",:order =>"patient.patient_id ASC").uniq rescue nil
  end

  def self.records_that_were_updated(quater)
    order_type = OrderType.find_by_name("Give drugs").id
    encounter_type = EncounterType.find_by_name("Give drugs").id
    concept_id = Concept.find_by_name("Appointment date").id
    date = self.cohort_date(quater)
    start_date = (date.to_s + " 00:00:00")
    end_date = date + 3.month - 1.day
    end_date = (end_date.to_s + " 23:59:59")
    voided_records = Hash.new()

    other_encounters = Encounter.find(:all,
                 :joins => "INNER JOIN obs ON encounter.encounter_id=obs.encounter_id",
                 :conditions => ["obs.voided=1 AND encounter.encounter_datetime >= ? AND encounter.encounter_datetime <= ? 
                 AND obs.concept_id NOT IN (?)",start_date,end_date,concept_id],
                 :group => "encounter.encounter_type,Date(encounter.encounter_datetime)",:order =>"encounter.encounter_type DESC")

    drug_encounters = Encounter.find(:all,
                 :joins => "INNER JOIN orders od ON encounter.encounter_id=od.encounter_id",
                 :conditions => ["od.voided=1 AND encounter.encounter_datetime >= ?
                 AND encounter.encounter_datetime <= ? AND od.order_type_id=?",start_date,end_date,order_type],
                 :group => "encounter.encounter_type,Date(encounter.encounter_datetime)",:order =>"encounter.encounter_type DESC")

    other_encounters.each{|encounter|
      patient = Patient.find(encounter.patient_id)
      obs = encounter.observations
      changed_to = self.changed_to(encounter)
      changed_from = self.changed_from(obs)

      voided_records[encounter.id]={"id" =>patient.patient_id,"arv_number" => patient.arv_number,
                    "name" =>patient.name,"national_id" =>patient.national_id,
                    "encounter_name" =>encounter.name,"voided_date" =>obs[0].date_voided,"reason" => obs[0].void_reason,
                    "change_from" =>changed_from,"change_to" => changed_to}
    }

    drug_encounters.each{|encounter|
      patient = Patient.find(encounter.patient_id)
      drug_orders = encounter.drug_orders
      orders = encounter.orders
      changed_from=''
      changed_to =''
         
      new_order = Encounter.find(:first,
                                 :joins => "INNER JOIN orders o ON encounter.encounter_id=o.encounter_id",
                                 :conditions =>["encounter_type=? AND patient_id=? AND 
                                 Date(encounter_datetime)=? AND o.order_type_id=? AND o.voided=0",
                                 encounter_type,encounter.patient_id,encounter.encounter_datetime.to_date,order_type])


      drug_orders.collect{|drug_order|changed_from+="#{drug_order.drug.short_name} (#{drug_order.quantity})</br>"}  
      new_order.drug_orders.collect{|drug_order|changed_to+="#{drug_order.drug.short_name} (#{drug_order.quantity})</br>"}  rescue ""
      changed_from = changed_from[0..-6] rescue ''
      changed_to = changed_to[0..-6] rescue ''

      voided_records[encounter.id]={"id" =>patient.patient_id,"arv_number" => patient.arv_number,
                    "name" =>patient.name,"national_id" =>patient.national_id,
                    "encounter_name" =>encounter.name,"voided_date" =>orders[0].date_voided,"reason" => orders[0].void_reason,
                    "change_from" =>changed_from,"change_to" => changed_to}
    }

    voided_records
  end

  def self.changed_from(observations)
    changed_obs =''
    observations.collect{|obs|
      next if obs.voided == 0
      ["value_coded","value_datetime","value_modifier","value_numeric","value_text"].each{|value|
        case value
          when "value_coded" 
            next if obs.value_coded.blank?
            changed_obs+="#{obs.to_s}</br>"
          when "value_datetime" 
            next if obs.value_datetime.blank?
            changed_obs+="#{obs.to_s}</br>"
          when "value_numeric" 
            next if obs.value_numeric.blank?
            changed_obs+="#{obs.to_s}</br>"
          when "value_text" 
            next if obs.value_text.blank?
            changed_obs+="#{obs.to_s}</br>"
          when "value_modifier" 
            next if obs.value_modifier.blank?
            changed_obs+="#{obs.to_s}</br>"
        end
      }  
    }
    changed_obs.gsub("00:00:00 +0200","")[0..-6]
  end

  def self.changed_to(enc)
    encounter_type = enc.encounter_type
    encounter = Encounter.find(:first,
                 :joins => "INNER JOIN obs ON encounter.encounter_id=obs.encounter_id",
                 :conditions => ["obs.voided=0 AND encounter_type=? AND encounter.patient_id=?
                 AND Date(encounter.encounter_datetime)=?",encounter_type,enc.patient_id,
                 enc.encounter_datetime.to_date],
                 :group => "encounter.encounter_type",:order =>"encounter.encounter_datetime DESC")

    observations = encounter.observations rescue nil
    return if observations.blank?

    changed_obs =''
    observations.collect{|obs|
      ["value_coded","value_datetime","value_modifier","value_numeric","value_text"].each{|value|
        case value
          when "value_coded" 
            next if obs.value_coded.blank?
            changed_obs+="#{obs.to_s}</br>"
          when "value_datetime" 
            next if obs.value_datetime.blank?
            changed_obs+="#{obs.to_s}</br>"
          when "value_numeric" 
            next if obs.value_numeric.blank?
            changed_obs+="#{obs.to_s}</br>"
          when "value_text" 
            next if obs.value_text.blank?
            changed_obs+="#{obs.to_s}</br>"
          when "value_modifier" 
            next if obs.value_modifier.blank?
            changed_obs+="#{obs.to_s}</br>"
        end
      }  
    }
    changed_obs.gsub("00:00:00 +0200","")[0..-6]
  end

end
