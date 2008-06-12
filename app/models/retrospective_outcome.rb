# This code is temporary for updating the occupation from the patient register
# This was needed to update outcomes
class RetrospectiveOutcome

  def execute
    User.current_user = User.find(:first)
    ask_arv_range  
    find_arv_patients_ids
    find_arv_patients
    update_outcomes
  end

  attr_accessor :arv_range, :arv_patient_ids, :arv_patients

  def ask_arv_range(start_number = nil, end_number = nil)
    unless start_number
      puts "Enter the starting ARV number (as a number)" 
      start_number = STDIN.gets.strip().to_i
    end
    unless end_number  
      puts "Enter the ending ARV number (as a number)"
      end_number = STDIN.gets.strip().to_i    
    end  
    @arv_range = (start_number..end_number).map {|n| "QEC #{n}"}  
  end

  def find_arv_patients_ids
    arv_national_id_type = PatientIdentifierType.find_by_name("ARV national id")
    identifiers = PatientIdentifier.find(:all, :conditions => 
      ['identifier_type = ? and identifier IN (?)', arv_national_id_type.id, @arv_range])    
    @arv_patient_ids = identifiers.map(&:patient_id)  
  end
  
  def find_arv_patients
    @arv_patients = Patient.find(:all, :include => [:patient_names, :patient_identifiers],
      :conditions => ['patient.patient_id IN (?)', @arv_patient_ids])
    @arv_patients = @arv_patients.sort{|a,b| a.arv_number <=> b.arv_number}  
  end

  def update_outcomes(default = nil)
    @arv_patients.each {|patient| 
      begin
        puts ""
        puts "-----------------------------------------------------------------"
        puts "#{patient.arv_number}: #{patient.first_name} #{patient.last_name}"
        puts "Current outcome: #{patient.outcome_status}"
        puts "-----------------------------------------------------------------"
        puts "Please type the number of the occupation for this patient:"
        puts "  (1) Stop"
        puts "  (2) Died"
        puts "  (3) Transfer out with note"
        puts "  (4) Transfer out without note"
        puts "  (5) On ART"
        puts "  (6) Never started"
        puts "  (0) Skip"
        ans = default ? default : STDIN.gets.strip().to_i
        case ans 
          when 1
            update_outcome(patient, "Stop")
          when 2
            update_outcome(patient, "Died")
          when 3
            update_outcome(patient, "Transfer Out(With Transfer Note)")
          when 4
            update_outcome(patient, "Transfer Out(Without Transfer Note)")
          when 5
            update_outcome(patient, "On ART")
          when 6
            update_outcome(patient, "Never Started ART")
        end  
        patient.save! unless ans == 0
      rescue Exception => e
        puts "You have input an invalid value #{ans}, patient skipped (#{e})"
      end    
    }
  end

  def update_outcome(patient, outcome, location = nil)
    encounter_datetime = Date.today
    outcome_year, outcome_month, outcome_day = get_year_month_day()
    give_drugs_encounters = patient.encounters.find_by_type_name("Give drugs")
    unless give_drugs_encounters.nil? or give_drugs_encounters.empty?
      end_date = give_drugs_encounters.last.encounter_datetime    
		else
	    end_date = Date.today					
		end
    
    if (outcome_day == "Unknown" or outcome_month == "Unknown" or outcome_year == "Unknown")
      encounter_date = estimate_outcome_date(end_date, encounter_datetime, outcome_year, outcome_month, outcome_day) 
      estimate = true
    else
      encounter_date = outcome_day.to_s + "-" + outcome_month.to_s + "-" + outcome_year.to_s
    end
    encounter = Encounter.new
    observation = Observation.new
    encounter.type = EncounterType.find_or_create_by_name("Update outcome")
    encounter.patient_id = patient.patient_id
    observation.patient_id = patient.patient_id    
    observation.concept_id = Concept.find_by_name("Outcome").concept_id
    observation.value_coded = Concept.find_by_name(outcome).concept_id
    observation.value_modifier = "estimated" if estimate == true
    case outcome
      when "Died"
        observation.obs_datetime = encounter_date.to_date 
        patient.death_date = encounter_date.to_date
        patient.save!
      when "ART Stop"
        observation.obs_datetime = encounter_date.to_date 
      else
        observation.obs_datetime = encounter_datetime
    end
    encounter.provider_id = User.current_user.user_id
    encounter.encounter_datetime = Time.now() 
    encounter.save!
    observation.encounter = encounter
    observation.save!
  end

  def estimate_outcome_date(last_visit_date, current_date, year="Unknown", month="Unknown", day="Unknown")
    return "#{year}-#{month}-15".to_date if day == "Unknown" && month != "Unknown" && year != "Unknown"
    if month == "Unknown"
      month_estimate = last_visit_date.to_time.month + (current_date.month - last_visit_date.to_time.month).div(2) 
      return "#{year}-#{month_estimate}-15".to_date if year != "Unknown"
    end
    if year == "Unknown"
      year_estimate = last_visit_date.to_time + ((current_date.to_time - last_visit_date.to_time).quo(2))
      return "#{year_estimate}".to_date 
    end  
  end


  def get_year_month_day
    default = "Unknown"
    year = nil
    while year == nil
      begin
        puts "   > Enter the year (required): "
        year = STDIN.gets.strip().to_i
        year = nil if year == 0
      rescue
        puts "Invalid year #{year}"
        year = nil
      end  
    end  
    puts "   > Enter the month (0 for Unknown): "
    month = STDIN.gets.strip().to_i
    month = default if month == 0
    puts "   > Enter the day (0 for Unknown): "
    day = STDIN.gets.strip().to_i
    day = default if day == 0
    return year, month, day
  end
   
end 
