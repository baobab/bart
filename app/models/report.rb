class Report < OpenMRS
  set_table_name "report"
  belongs_to :user, :foreign_key => :user_id
  set_primary_key "report_id"

  cattr_accessor :cohort_patient_ids

  Report.cohort_patient_ids = {:all => [],
                            :occupations => {},
                            :start_reasons => {},
                            :outcome_data => {},
                            :of_those_on_art => {},
                            :of_those_who_died => {}
  }

  def self.cache
    #TODO fix this so that it uses render_to_string instead of wget
    # these need to be added to controllers/application to make sure logins aren't required
    # These are all URLs that should be cached
    q="Q2_" + Date.today.year.to_s
    q2="Q1_" + Date.today.year.to_s
    q3="Q4_" + (Date.today.year - 1).to_s
    q4="Q3_" + (Date.today.year - 1).to_s
    q5="Q2_" + (Date.today.year - 1).to_s
#    q6="Q3_" + Date.today.year.to_s
#    q7="Q4_" + Date.today.year.to_s

    urls = [
#           "reports/virtual_art_register", TODO: needs to be optimised
#           "reports/monthly_drug_quantities", TODO: Fix crash
          
          # These reports are crashing. Test them before enabling
          # "reports/missed_appointments",
          # "reports/height_weight_by_user",
#           "reports/defaulters",
           "reports/cohort/#{q}",
           "reports/cohort/#{q2}",
           "reports/cohort/#{q3}",
           "reports/cohort/#{q4}",
           "reports/cohort/#{q5}",
#           "reports/cohort/#{q6}",
#           "reports/cohort/#{q7}"
          ]

    #base_url = request.env["HTTP_HOST"]
    base_url = "localhost"
    base_url += ":3000" if RAILS_ENV == "development"
    @urls = Hash.new

    urls.each{|report_url|
      output_document = "/tmp/bart_last_cached_report.html"
      original_url = "http://#{base_url}/#{report_url}"
      command = "wget --timeout=0 --output-document #{output_document} #{original_url}?refresh=true"
      # Start this in a thread, otherwise we can block the whole app (depending on how concurrency is setup)
      Thread.new{
        #yell "#{command}"
        #yell `#{command}`
        `#{command}`
      }
    }

  end

  def self.survival_analysis_hash(survival_patients, start_date, end_date, outcome_end_date, count)
    registration_start_date = start_date
    registration_end_date = end_date
    outcome_end_date = outcome_end_date
    outcomes = Hash.new

    outcomes["Defaulted"] = 0
    outcomes["On ART"] = 0
    outcomes["Died"] = 0
    outcomes["ART Stop"] = 0
    outcomes["Transfer out"] = 0

    outcomes["Title"] = "#{count*12} month survival: outcomes by end of #{outcome_end_date.strftime('%B %Y')}"
    outcomes["Total"] = survival_patients.length
    outcomes["Start Date"] = start_date
    outcomes["End Date"] = end_date
    
    survival_patients.each{|patient|
      patient_outcome = patient.cohort_outcome_status(registration_start_date, outcome_end_date)

      if (patient_outcome.downcase.include?("on art") and patient.defaulter?(outcome_end_date)) or patient_outcome == "Defaulter"
        outcomes["Defaulted"] += 1
      elsif patient_outcome.include?("Died")
        outcomes["Died"] += 1
      elsif patient_outcome.include?("ART Stop")
        outcomes["ART Stop"] += 1
      elsif patient_outcome.include?("Transfer")
        outcomes["Transfer out"] += 1
      elsif patient_outcome.downcase.include?("on art")
        outcomes["On ART"] += 1
      else
        if outcomes.has_key?(patient_outcome) then
          outcomes[patient_outcome] += 1
        else
          outcomes[patient_outcome] = 1
        end
      end

    }
    return outcomes
  end

  def self.cohort_range(date)
    year = date.year
    if date >= "#{year}-01-01".to_date and date <= "#{year}-03-31".to_date
      quarter = "Q1 #{year}"
    elsif date >= "#{year}-04-01".to_date and date <= "#{year}-06-30".to_date
      quarter = "Q2 #{year}"
    elsif date >= "#{year}-07-01".to_date and date <= "#{year}-09-30".to_date
      quarter = "Q3 #{year}"
    elsif date >= "#{year}-10-01".to_date and date <= "#{year}-12-31".to_date
      quarter = "Q4 #{year}"
    end
    self.cohort_date_range(quarter)
  end
 
  def self.cohort_date_range(quarter_text, start_date=nil, end_date=nil)
    quarter_end_hash = {"Q1"=>"mar-31", "Q2"=>"jun-30","Q3"=>"sep-30","Q4"=>"dec-31"}
    quarter_start = nil
    quarter_end = nil
		if quarter_text == "Cumulative"
      quarter_start = start_date.to_date rescue nil if start_date
      quarter_end = end_date.to_date rescue nil if end_date
      
      quarter_start = Encounter.find(:first, :order => 'encounter_datetime').encounter_datetime.to_date if quarter_start.nil?
      if quarter_end.nil?
        quarter_end = Date.today
        censor_date = (quarter_end.year-1).to_s + "-" + "dec-31"

        quarter_end_hash.each{|a,b|
          break if quarter_end < (quarter_end.year.to_s+"-"+b).to_date
          censor_date = quarter_end.year.to_s+"-"+b
        }
        quarter_end = censor_date.to_date
      end

		else
			# take the cohort string that was passed in ie. "Q1 2006", split it on the space and save it as two separate variables
      quarter_text.gsub!('+',' ')
      quarter_text.gsub!('_',' ')
			quarter, quarter_year = quarter_text.split(" ")
      return [nil, nil] unless quarter =~ /Q[1-4]/ and quarter_year =~ /\d\d\d\d/
			quarter_month_hash = {"Q1"=>"January", "Q2"=>"April","Q3"=>"July","Q4"=>"October"}
			quarter_month = quarter_month_hash[quarter]
		 
			quarter_start = (quarter_year + "-" + quarter_month + "-01").to_date 
			quarter_end = (quarter_year + "-" + quarter_end_hash[quarter]).to_date
    end
    
    return [quarter_start, quarter_end]

  end

  def self.quarter_end_date
    quarter_dates = {'01-01' => ['03-31', 1],
                     '04-01' => ['06-30', 2],
                     '07-01' => ['09-30', 3],
                     '10-01' => ['12-31', 4],
    }
    return quarter_dates #[start_date.strftime('%m-%d')]
  end

  def self.cached_cohort_quarters
    report_quarters = CohortReportFieldValue.find(:all, 
                                                  :select => 'start_date, end_date',
                                                  :conditions => ['start_date > ?', '1900-01-01'], 
                                                  :group => 'end_date,start_date')
    report_quarters.map do |quarter|
      "Q#{self.quarter_end_date[quarter.start_date.strftime('%m-%d')][1].to_s} #{quarter.start_date.year}" rescue nil
    end.compact
  end

  def self.user_stat_data(start_date,end_date,user_name)
    user_id = User.find_by_username(user_name).id rescue nil
    return if user_id.blank?
    encounters = Encounter.encounters_by_start_date_end_date_and_user(start_date.to_date,end_date.to_date,user_id) 
    encounter_count = Hash.new(0)
    encounter_count_to_display = Hash.new()
    encounters.each{|e|
      next if e.name == "Barcode scan"  
      encounter_count["#{e.name},#{e.encounter_datetime.strftime('%Y_%m_%d')}"]+=1
    }
    encounter_count.each{|x,y|
      next if x.split(",").first == ""  
      encounter_count_to_display[x.split(",").first]+= x.split(",").last + ":" + y.to_s + ";" unless encounter_count_to_display[x.split(",").first].blank?
      encounter_count_to_display[x.split(",").first]= x.split(",").last + ":" + y.to_s + ";" if encounter_count_to_display[x.split(",").first].blank?
    }
    encounter_count_to_display
  end


 def self.stats_to_show(stat_type)
   encounters = stat_type.gsub("_","-").split(";")
   stats_per_day = Hash.new()
   encounters.each{|e|stats_per_day[e.split(':').first.to_date] = e.split(':').last}
   week = Hash.new()
   week_count = 1
   key = "week_#{week_count}"
   week_data = self.create_resuts_for_individual_stats_per_week(stats_per_day.sort{|a,b|b<=>a}.map{|x,y|x}.first.to_date)
   week[key] = week_data

   stats_per_day.sort{|a,b|b<=>a}.each{|date,value|
    valid_key = ""
    week.each{|x,y|valid_key = x if week[key].include?(date.strftime("%a, %d %b %Y"))} 
    key = "" if valid_key.blank?

    if key == "" then
      week_data = self.create_resuts_for_individual_stats_per_week(date.to_date)
      key = "week_#{week_count+=1}"
      week[key]=week_data
      week[key][date.to_date.strftime("%u").to_i - 1] = "#{date.strftime("%a, %d %b %Y")}: #{value}" 
    else 
      week[key][date.to_date.strftime("%u").to_i - 1] = "#{date.strftime("%a, %d %b %Y")}: #{value}" 
    end
   }
   week 
 end
  
 def self.create_resuts_for_individual_stats_per_week(date)

   case date.strftime('%A')
     when 'Monday'
       week = [date,date + 1.day,date + 2.day,date + 3.day,date + 4.day,date + 5.day,date + 6.day]
       week.collect{|week_days|week_days.strftime("%a, %d %b %Y")}
     when 'Tuesday'
       week = [date - 1.day,date,date + 1.day,date + 2.day,date + 3.day,date + 4.day,date + 5.day]
       week.collect{|week_days|week_days.strftime("%a, %d %b %Y")}
     when 'Wednesday'
       week = [date - 2.day,date -1.day,date,date + 1.day,date + 2.day,date + 3.day,date + 4.day]
       week.collect{|week_days|week_days.strftime("%a, %d %b %Y")}
     when 'Thursday'
       week = [date - 3.day,date - 2.day,date - 1.day,date,date + 1.day,date + 2.day,date + 3.day]
       week.collect{|week_days|week_days.strftime("%a, %d %b %Y")}
     when 'Friday'
       week = [date - 4.day,date - 3.day,date - 2.day,date - 1.day,date,date + 1.day,date + 2.day]
       week.collect{|week_days|week_days.strftime("%a, %d %b %Y")}
     when 'Saturday'
       week = [date - 5.day,date - 4.day,date - 3.day,date - 2.day,date - 1.day,date,date + 1.day]
       week.collect{|week_days|week_days.strftime("%a, %d %b %Y")}
     when 'Sunday'
       week = [date - 6.day,date - 5.day,date - 4.day,date - 3.day,date - 2.day,date -1.day,date]
       week.collect{|week_days|week_days.strftime("%a, %d %b %Y")}
   end
 end 
  
 def self.detail_user_encounter_results_html(data,stat_name,user_name)
   html = ""
   stat_name ||=""
   user_name ||=""
   data.sort{|b,a|b.to_s.split("_")[1].to_i<=>a.to_s.split("_")[1].to_i}.each{|key,v|
     results_to_be_passed_string = "#{v[0][17..-1].to_i rescue 0},#{v[1][17..-1].to_i rescue 0},#{v[2][17..-1].to_i rescue 0},#{v[3][17..-1].to_i rescue 0},#{v[4][17..-1].to_i rescue 0},#{v[5][17..-1].to_i rescue 0},#{v[6][17..-1].to_i rescue 0}"
     total = 0
     results_to_be_passed_string.split(",").each{|x|total+=x.to_i rescue ""}
     date = "#{v[0][0..15].to_date.strftime('%d-%b-%Y')}"
     html+= "<tr><td class='button_td'><input class='test_name' type=\"button\" onmousedown=\"document.location='/reports/user_stats_graph?id=#{results_to_be_passed_string}&date=#{date}&user_name=#{user_name}&stat_name=#{stat_name}';\" value=\"#{v[0][0..15].to_date.strftime('%d-%b-%Y')} - #{v[6][0..15].to_date.strftime('%d-%b-%Y')}\"/></td><td class='data_td'>#{v[0][17..-1]}</td><td class='data_td'>#{v[1][17..-1]}</td><td class='data_td'>#{v[2][17..-1]}</td><td class='data_td'>#{v[3][17..-1]}</td><td class='data_td'>#{v[4][17..-1]}</td><td class='data_td'>#{v[5][17..-1]}</td><td class='data_td'>#{v[6][17..-1]}</td><td class='data_totals_td'>#{total}</td></tr>"
   }
   html
 end

 def self.genrept_hiv_reception(start_date,end_date)
   encounter_types = EncounterType.find(:all,:conditions => ["(name=? or name=?)","General Reception","HIV Reception"]).map{|type|type.id}  rescue nil

   hiv_ecounters = Encounter.find(:all,:conditions => ["encounter_type=? and (encounter_datetime >=? and encounter_datetime <=?)",encounter_types.first,start_date.to_date,end_date.to_date],:group => "patient_id",:order => "encounter_datetime asc")
   genrept_patients = Encounter.find(:all,:conditions => ["encounter_type=? and (encounter_datetime >=? and encounter_datetime <=?)",encounter_types.last,start_date.to_date,end_date.to_date],:group => "patient_id",:order => "encounter_datetime asc")
   all_patients = Hash.new()
   hiv_patients = Hash.new()
   hiv_ecounters.each{|enc|
     hiv_patients[enc.patient_id] = "#{enc.encounter_type},#{enc.encounter_datetime.to_date}" if hiv_patients[enc.patient_id].blank? 
   }
   
   genrept_patients.each{|enc|
     all_patients[enc.patient_id] = "#{enc.encounter_type},#{enc.encounter_datetime.to_date};#{hiv_patients[enc.patient_id]}" unless hiv_patients[enc.patient_id].blank? 
   }
   
   all_patients
 end

 def self.appointment_dates(date=Date.today)
   app_concept_id = Concept.find_by_name("Appointment date").concept_id rescue nil
   Patient.find(:all,:joins => 'INNER JOIN `obs` ON patient.patient_id = obs.patient_id',
                :conditions => ["Date(obs.value_datetime) = ? and obs.concept_id = ?  and obs.voided=0",
                date.to_date,app_concept_id],:group => "obs.patient_id") 

 end

 def self.missed_appointments(date = Date.today)
   app_date = date.to_date
   encounter_ids = Array.new()
   encounter_ids << EncounterType.find_by_name("Barcode scan").id
   encounter_ids << EncounterType.find_by_name("TB Reception").id
   encounter_ids << EncounterType.find_by_name("General Reception").id
   encounter_ids << EncounterType.find_by_name("Move file from dormant to active").id
   encounter_ids << EncounterType.find_by_name("Update outcome").id
   concept_id = Concept.find_by_name("Appointment date").concept_id rescue nil

   patient_ids = Observation.find(:all,:select => "patient_id",:conditions => ["voided = 0 AND concept_id = ? AND Date(value_datetime) = ?",concept_id,app_date],:group =>"patient_id").collect{|ob|ob.patient_id}.join(",") rescue nil
  
   return if patient_ids.blank?

   patients = Patient.find_by_sql("SELECT * FROM patient p WHERE patient_id IN (#{patient_ids}) AND NOT EXISTS (SELECT * FROM obs o WHERE o.patient_id = p.patient_id AND o.voided - 0 AND DATE(o.obs_datetime) = '#{app_date}') AND NOT EXISTS (SELECT * FROM orders o INNER JOIN encounter e ON e.encounter_id = o.encounter_id AND o.voided = 0 WHERE e.patient_id = p.patient_id AND DATE(e.encounter_datetime) = '#{app_date}' AND NOT e.encounter_type IN (#{encounter_ids}))")

   patients = CohortTool.patients_to_show(patients)
   arv_code = Location.current_arv_code
   patients.sort { |a,b| a[1]['arv_number'].to_s.gsub(arv_code,'').strip.to_i <=> b[1]['arv_number'].to_s.       gsub(arv_code,'').strip.to_i }
 end

end

