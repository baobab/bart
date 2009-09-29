class CohortTool < OpenMRS
  set_table_name "encounter"

  def self.adherence(quater="Q1 2009")
    date = Report.cohort_date_range(quater)
     
    start_date = (date.first.to_s + " 00:00:00")
    end_date = (date.last.to_s + " 23:59:59")
    adherences = Hash.new(0)

    adherence_rates = PatientAdherenceRate.find(:all,
                 :conditions => ["visit_date >= ? AND visit_date <= ? AND adherence_rate IS NOT NULL",
                 start_date.to_date,end_date.to_date],
                 :group => "patient_id",:order => "Date(visit_date) DESC")

    adherence_rates.each{|adherence|
      rate = adherence.adherence_rate.to_i
      if rate >= 95 and rate <= 105
        cal_adherence = 100
      elsif  rate > 105 and rate <= 109
        cal_adherence = 106
      else  
        cal_adherence = (rate - (rate%5))
      end  
      adherences[cal_adherence]+=1
    }
    adherences
  end
  
  def self.patients_visits_per_day(date)
    date = [date.to_date,date.to_date]
    start_date = (date.first.to_s + " 00:00:00")
    end_date = (date.last.to_s + " 23:59:59")
    encounter_ids = Array.new()
    encounter_ids << EncounterType.find_by_name("Barcode scan").id
    encounter_ids << EncounterType.find_by_name("TB Reception").id
    encounter_ids << EncounterType.find_by_name("General Reception").id
    encounter_ids << EncounterType.find_by_name("Move file from dormant to active").id
    encounter_ids << EncounterType.find_by_name("Update outcome").id

    patients = Patient.find(:all,
                           :joins => "INNER JOIN encounter ON encounter.patient_id = patient.patient_id
                           INNER JOIN obs ON obs.encounter_id = encounter.encounter_id",
                           :conditions => ["obs.voided = 0 AND encounter_type NOT IN (?) AND encounter_datetime >=? AND encounter_datetime <=?",
                           encounter_ids,start_date,end_date],
                           :group => "encounter.patient_id,DATE(encounter_datetime)",:order => "encounter_datetime ASC")

    patients = self.patients_to_show(patients)
    arv_code = Location.current_arv_code
    patients.sort { |a,b| a[1]['arv_number'].to_s.gsub(arv_code,'').strip.to_i <=> b[1]['arv_number'].to_s.gsub(arv_code,'').strip.to_i }
  end

  def self.adherence_over_hundred(quater="Q1 2009",min_range = nil,max_range=nil)
    date = Report.cohort_date_range(quater)
     
    start_date = (date.first.to_s + " 00:00:00")
    end_date = (date.last.to_s + " 23:59:59")
    patients = {}

    if min_range.blank? or max_range.blank?
      adherence_rates = PatientAdherenceRate.find(:all,
                 :conditions => ["visit_date >= ? AND visit_date <= ? AND adherence_rate IS NOT NULL AND adherence_rate > 100",
                 start_date.to_date,end_date.to_date],:group => "patient_id",:order => "Date(visit_date) DESC")
    else
      rates = PatientAdherenceRate.find(:all,
                 :conditions => ["visit_date >= ? AND visit_date <= ? AND adherence_rate IS NOT NULL",
                 start_date.to_date,end_date.to_date],
                 :group => "patient_id",:order => "Date(visit_date) DESC")
      patients_rates = []
      rates.each{|rate|
        if (rate.adherence_rate >= min_range.to_i and rate.adherence_rate <= max_range.to_i)
          #raise "#{min_range} -- #{max_range} ===#{rate.adherence_rate} "
          patients_rates << rate
        end  
      }
      adherence_rates = patients_rates
    end

    drug_count = {}
    drugs_remaining = PatientWholeTabletsRemainingAndBrought.find(:all,
         :conditions => ["visit_date >=?  AND visit_date <= ?",start_date.to_date,end_date.to_date],
                        :order => "Date(visit_date) DESC")
    drugs_remaining.each{|count|
      drug_name = Drug.find(count.drug_id).short_name
      prev_data = drug_count["#{count.patient_id},#{count.visit_date}"]
      drug_count["#{count.patient_id},#{count.visit_date}"] = "#{prev_data}</br>#{drug_name}:#{count.total_remaining}" unless drug_count["#{count.patient_id},#{count.visit_date}"].blank?
      drug_count["#{count.patient_id},#{count.visit_date}"] = "#{drug_name}:#{count.total_remaining}" if drug_count["#{count.patient_id},#{count.            visit_date}"].blank?
    }

    adherence_rates.each{|rate|
      patient = Patient.find(rate.patient_id)
      patients[patient.patient_id]={"id" =>patient.id,"arv_number" => patient.arv_number,
                           "name" =>patient.name,"national_id" =>patient.national_id,"visit_date" =>rate.visit_date,
                           "gender" =>patient.sex,"age" =>patient.age_at_initiation,"birthdate" => patient.birthdate,
                           "pill_count" => drug_count["#{patient.id},#{rate.visit_date}"],
                           "adherence" => rate.adherence_rate,"start_date" => patient.date_started_art,
                           "expected_count" =>self.expected_pills_remaining(patient,rate.visit_date)}
    }
  
    arv_code = Location.current_arv_code
    patients.sort { |a,b| a[1]['arv_number'].to_s.gsub(arv_code,'').strip.to_i <=> b[1]['arv_number'].to_s.gsub(arv_code,'').strip.to_i }
  end
 
  def self.expected_pills_remaining(patient,visit_date)
    date = visit_date.to_date
    expected_pills = ""
    pills = PatientAdherenceRate.find(:all,
            :conditions =>["patient_id = ? AND visit_date = ?",patient.id,date])
    pills.each{|count|
       drug = Drug.find(count.drug_id) 
       expected_pills+="</br>#{drug.short_name}:#{count.expected_remaining}" unless expected_pills.blank?
       expected_pills="#{drug.short_name}:#{count.expected_remaining}" if expected_pills.blank?
    }
    expected_pills
  end

  def self.visits_by_day(quater)
    date = Report.cohort_date_range(quater)
    start_date = (date.first.to_s + " 00:00:00")
    end_date = (date.last.to_s + " 23:59:59")
    encounter_ids = Array.new()
    encounter_ids << EncounterType.find_by_name("Barcode scan").id
    encounter_ids << EncounterType.find_by_name("TB Reception").id
    encounter_ids << EncounterType.find_by_name("General Reception").id
    encounter_ids << EncounterType.find_by_name("Move file from dormant to active").id
    encounter_ids << EncounterType.find_by_name("Update outcome").id

    visits_by_day = Hash.new(0)

    encounters = self.find(:all,
                           :joins => "INNER JOIN obs ON obs.encounter_id = encounter.encounter_id",
                           :conditions => ["obs.voided = 0 AND encounter_type NOT IN (?) AND encounter_datetime >=? AND encounter_datetime <=?",
                           encounter_ids,start_date,end_date],
                           :group => "encounter.patient_id,DATE(encounter_datetime)",:order => "encounter_datetime ASC")

    encounters.each{|encounter|
      visits_by_day[encounter.encounter_datetime.strftime("%d-%b-%Y")]+=1
    }
    visits_by_day
  end


  def self.in_arv_number_range(quater,min,max)
    date = Report.cohort_date_range(quater)
    start_date = (date.first)
    end_date = (date.last)

    cohort = Reports::CohortByRegistrationDate.new(start_date,end_date)
 
    patients = self.patients_to_show(cohort.in_arv_number_range(min, max))
    arv_code = Location.current_arv_code
    patients.sort { |a,b| a[1]['arv_number'].to_s.gsub(arv_code,'').strip.to_i <=> b[1]['arv_number'].to_s.gsub(arv_code,'').strip.to_i }
  end

  def self.patients_to_show(pats)
    patients = Hash.new()
    pats.each{|patient|
      patients[patient.id]={"id" =>patient.id,"arv_number" => patient.arv_number,
                           "name" =>patient.name,"national_id" =>patient.national_id,
                           "gender" =>patient.sex,"age" =>patient.age_at_initiation,"birthdate" => patient.birthdate,
                           "start_date" => patient.date_started_art}
    }
   patients
  end

  def self.cohort_debugger_patients(pats)
    patients = Hash.new()
    pats.each{|patient|
      patients[patient.id]={"id" =>patient.id,"arv_number" => patient.arv_number,
                           "name" =>patient.name,"gender" =>patient.sex,"age" =>patient.age_at_initiation,
                           "date_started_art" => patient.date_started_art,
                           "reason_for_art_eligibility" => patient.reason_for_art_eligibility}
    }
    arv_code = Location.current_arv_code
    patients.sort { |a,b| a[1]['arv_number'].to_s.gsub(arv_code,'').strip.to_i <=> b[1]['arv_number'].to_s.gsub(arv_code,'').strip.to_i }
  end

  def self.internal_consistency_checks(quater)
    date = Report.cohort_date_range(quater)
    start_date = (date.first.to_s + " 00:00:00")
    end_date = (date.last.to_s + " 23:59:59")
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
          patients["possible_male_patients_with_wrong_gender_assigned"] = self.patients_with_possible_wrong_sex(male_names,start_date,end_date,"Female")
        when "male"
          patients["possible_female_patients_with_wrong_gender_assigned"] = self.patients_with_possible_wrong_sex(female_names,start_date,end_date,"Male")
        end
    }
    
    patients["wrong_start_dates"] = self.patients_with_start_dates_less_than_first_give_drug_date(start_date,end_date)

    patients["male_patients_with_a_pregnant_observation"] = self.male_patients_with_pregnant_obs(start_date,end_date)

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
    date = Report.cohort_date_range(quater)
    start_date = (date.first.to_s + " 00:00:00")
    end_date = (date.last.to_s + " 23:59:59")
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

    #return voided_records
    self.show_voided_records_only(voided_records)
  end

  def self.show_voided_records_only(records)
    records.each{|key,values|
      changed_from = values["change_from"].split("</br>") rescue []
      changed_from_new = values["change_from"]
      changed_to = values["change_to"]
      changed_from.each{|data|
        next unless changed_from_new.include?("#{data}</br>")
        next if changed_to.blank?
        next unless changed_to.include?("#{data}</br>")

        changed_to = changed_to.gsub("#{data}</br>","") 
        changed_from_new = changed_from_new.gsub("#{data}</br>","")
      }
      records[key]["change_from"] = changed_from_new
      records[key]["change_to"] = changed_to
    }
    records
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
  
  def self.patient_last_visit_day_in_cohort_quater(patient,quater="Q1 #{Date.today.year}")
    date = Report.cohort_date_range(quater)
    start_date = (date.first.to_s + " 00:00:00")
    end_date = (date.last.to_s + " 23:59:59")
    PatientAdherenceRate.find(:first,:conditions => ["patient_id=? AND visit_date >=? AND visit_date <=?",
                              patient.patient_id,start_date.to_date,end_date.to_date],
                              :order => "Date(visit_date) DESC").visit_date rescue nil
  end

  def self.visits_by_day_results_html(data)
   html = ""
   week_count = 1
   data.sort{|b,a|a.to_s.split("_")[1].to_i<=>b.to_s.split("_")[1].to_i}.each{|key,v|
     results_to_be_passed_string = "#{v[0][17..-1].to_i rescue 0},#{v[1][17..-1].to_i rescue 0},#{v[2][17..-1].to_i rescue 0},#{v[3][17..-1].to_i rescue 0}, #{v[4][17..-1].to_i rescue 0},#{v[5][17..-1].to_i rescue 0},#{v[6][17..-1].to_i rescue 0}"
     total = 0
     results_to_be_passed_string.split(",").each{|x|total+=x.to_i rescue ""}
     date = "#{v[0][0..15].to_date.strftime('%d-%b-%Y')}"
     html+= "<tr><td class='button_td'><div>Week #{week_count}:#{'&nbsp;'*5}#{v[0][0..15].to_date.strftime('%d-%b-%Y')} to #{v[6][0..15].to_date.strftime('%d-%b-%Y')}</div></td><td class='data_td'>#{v[0][17..-1]}</td><td class='data_td'>#{v[1][17..-1]}</td><td class='data_td'>#{v[2][17..-1]}</td><td class='data_td'>#{v[3][17..-1]}</td><td class='data_td'>#{v[4][17..-1]}</td><td class='data_td'>#{v[5][17..-1]}</td><td class='data_td'>#{v[6][17..-1]}</td><td class='data_totals_td'>#{total}</td></tr>"
     week_count+=1
   }
   html
 end

 def self.totals_by_week_day(results)
   week_days = Hash.new()
   results.each{|week,day_total|
     day_total.each{|day|
       date = day.split(":")[0].to_date
       week_day = date.strftime("%a")
       total_count = day.split(":")[1].strip rescue 0
       week_date = week_days[week_day]
       week_days[week_day]="#{week_date}:#{date.strftime('%d-%b-%Y')}:#{total_count}" unless week_date.blank?
       week_days[week_day]="#{date.strftime('%d-%b-%Y')}:#{total_count}" if week_date.blank?
     }
   }
   week_days
 end         
 

end
