class Reports::CohortByRegistrationDate
   
  attr_accessor :start_date, :end_date
  @@age_at_initiation_join = 'INNER JOIN patient_start_dates ON patient_start_dates.patient_id = patient_registration_dates.patient_id'
  @@age_at_initiation_join_for_pills = 'INNER JOIN patient_start_dates ON patient_start_dates.patient_id = patient_whole_tablets_remaining_and_brought.patient_id'

  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date 

    @outcome_join = "INNER JOIN ( \
           SELECT * FROM ( \
             SELECT * \
             FROM patient_outcomes \
             WHERE outcome_date >= '#{@start_date.to_formatted_s}' AND outcome_date <= '#{@end_date.to_formatted_s}' \
             ORDER BY outcome_date DESC \
           ) as t GROUP BY patient_id \
        ) as outcome ON outcome.patient_id = patient_registration_dates.patient_id"
  end
   
  def patients_started_on_arv_therapy
    PatientRegistrationDate.count(:conditions => ["registration_date >= ? AND registration_date <= ?", @start_date, @end_date])
  end

  def men_started_on_arv_therapy
    PatientRegistrationDate.count(:include => [:patient], :conditions => ["registration_date >= ? AND registration_date <= ? AND patient.gender = 'Male'", @start_date, @end_date])
  end

  def women_started_on_arv_therapy
    PatientRegistrationDate.count(:include => [:patient], :conditions => ["registration_date >= ? AND registration_date <= ? AND patient.gender = 'Female'", @start_date, @end_date])
  end

  def adults_started_on_arv_therapy
    PatientRegistrationDate.count(:joins => @@age_at_initiation_join, :conditions => ["registration_date >= ? AND registration_date <= ? AND age_at_initiation >= ?", @start_date, @end_date, 15])
  end

  def children_started_on_arv_therapy
    PatientRegistrationDate.count(:joins => @@age_at_initiation_join, :conditions => ["registration_date >= ? AND registration_date <= ? AND age_at_initiation <= ?", @start_date, @end_date, 14])
  end

  def occupations
    occupation = PatientIdentifierType.find_by_name("Occupation").patient_identifier_type_id
    occupation_hash = Hash.new(0)
    PatientRegistrationDate.find(:all,
      :joins => 
        "INNER JOIN patient_identifier ON \
           patient_identifier.patient_id = patient_registration_dates.patient_id AND \
           patient_identifier.voided = 0 AND \
           patient_identifier.identifier_type = #{occupation}",
      :conditions => ["registration_date >= ? AND registration_date <= ?", @start_date, @end_date],
      :group => "identifier",
      :order => "patient_identifier.date_created DESC",
      :select => "identifier, count(*) as count").map {|r| 
        identifier = r.identifier.downcase
        identifier = 'soldier/police' if identifier =~ /police|soldier/
        occupation_hash[identifier] = r.count.to_i 
      }
    occupation_hash
  end

# Reason for starting
# WHO Stage III
# WHO Stage IV
# CD4 Count
# Lymphocyte count below threshold with WHO Stage 2
# KS

# TB <= Staging
# EPTB <= Staging
# Active PTB <= Staging
# PTB within the past 2 years <= Staging
# Pregnant women started on ART for PMTCT <= Staging
   
  def outcomes(start_date=@start_date, end_date=@end_date, outcome_end_date=@end_date)
    outcome_hash = Hash.new(0)
    # This find is difficult because you need to join in the outcomes, however
    # you want to get the most recent outcome for the period, meaning you have
    # to group and sort and filter all within the join
    PatientRegistrationDate.find(:all,
      :joins => 
        "INNER JOIN ( \
           SELECT * FROM ( \
             SELECT * \
             FROM patient_outcomes \
             INNER JOIN ( \
               SELECT concept_id, 0 AS sort_weight FROM concept WHERE concept_id = 322 \
               UNION SELECT concept_id, 1 AS sort_weight FROM concept WHERE concept_id = 386 \
               UNION SELECT concept_id, 2 AS sort_weight FROM concept WHERE concept_id = 374 \
               UNION SELECT concept_id, 3 AS sort_weight FROM concept WHERE concept_id = 383 \
               UNION SELECT concept_id, 4 AS sort_weight FROM concept WHERE concept_id = 325 \
               UNION SELECT concept_id, 5 AS sort_weight FROM concept WHERE concept_id = 373 \
               UNION SELECT concept_id, 6 AS sort_weight FROM concept WHERE concept_id = 324 \
             ) AS ordered_outcomes ON ordered_outcomes.concept_id = patient_outcomes.outcome_concept_id \
             WHERE outcome_date >= '#{start_date.to_formatted_s}' AND outcome_date <= '#{outcome_end_date.to_formatted_s}' \
             ORDER BY DATE(outcome_date) DESC, sort_weight \
           ) as t GROUP BY patient_id \
        ) as outcome ON outcome.patient_id = patient_registration_dates.patient_id",
      :conditions => ["registration_date >= ? AND registration_date <= ?", start_date, end_date],
      :group => "outcome_concept_id",
      :select => "outcome_concept_id, count(*) as count").map {|r| outcome_hash[r.outcome_concept_id.to_i] = r.count.to_i }
    outcome_hash
  end
   
  def regimens
    on_art_concept_id = Concept.find_by_name("On ART").id
    regimen_hash = Hash.new(0)
    # This find is difficult because you need to join in the outcomes and 
    # regimens, however you want to get the most recent outcome or regimen for 
    # the period, meaning you have to group and sort and filter all within the 
    # join. We use a left join for regimens so that unknown regimens show as 
    # NULL. 
    PatientRegistrationDate.find(:all,
      :joins => 
        "INNER JOIN ( \
          SELECT * FROM (
            SELECT * \
            FROM patient_outcomes \
            WHERE outcome_date >= '#{@start_date.to_formatted_s}' AND outcome_date <= '#{@end_date.to_formatted_s}' AND outcome_concept_id = #{on_art_concept_id} \
            ORDER BY outcome_date DESC \
          ) as t GROUP BY patient_id \
          
          ) as outcome ON outcome.patient_id = patient_registration_dates.patient_id
          LEFT JOIN ( \
            SELECT * FROM (
              SELECT * \
              FROM patient_regimens \
              WHERE dispensed_date >= '#{@start_date.to_formatted_s}' AND dispensed_date <= '#{@end_date.to_formatted_s}' \
              ORDER BY dispensed_date DESC \
            ) as t2 GROUP BY patient_id \
          LIMIT 1
        ) as regimen ON regimen.patient_id = patient_registration_dates.patient_id",
      :conditions => ["registration_date >= ? AND registration_date <= ?", @start_date, @end_date],            
      :group => "regimen_concept_id",
      :select => "regimen_concept_id, count(*) as count").map {|r| regimen_hash[r.regimen_concept_id.to_i] = r.count.to_i }
    regimen_hash
  end
   
  def side_effects
    side_effects_hash = {}
    ["Is able to walk unaided",
     "Is at work/school",
     "Peripheral neuropathy", 
     "Leg pain / numbness",
     "Hepatitis", 
     "Jaundice",
     "Skin rash",
     "Lipodystrophy",
     "Lactic acidosis",
     "Anaemia",
     "Other symptom", 
     "Other side effect"].map {|symptom|  
      concept_id = Concept.find_by_name(symptom).id 
      side_effects_hash[concept_id] = count_observations_for(concept_id)
    }
    side_effects_hash    
  end
  
  # Adults on 1st line regimen with pill count done in the last month of the quarter
  # We implement this as last month of treatment in this period
  # Later join this so it is first line reg
  def adults_on_first_line_with_pill_count
    ## TODO, not limiting to first line
    PatientWholeTabletsRemainingAndBrought.find(:all,                                              
      :joins => 
        "#{@@age_at_initiation_join_for_pills}  INNER JOIN patient_registration_dates \
           ON registration_date >= '#{@start_date.to_formatted_s}' AND registration_date <= '#{@end_date.to_formatted_s}' AND \
              patient_registration_dates.patient_id = patient_whole_tablets_remaining_and_brought.patient_id AND \
              patient_start_dates.age_at_initiation >= 15
         
        #{@outcome_join}",
      :conditions => ["visit_date >= ? AND visit_date <= ? AND outcome_concept_id = ?", @start_date, @end_date, 324],      
      :group => "patient_whole_tablets_remaining_and_brought.patient_id").size
  end
  
  # With pill count in the last month of the quarter at 8 or less
  def adults_on_first_line_with_pill_count_with_eight_or_less
    ## TODO, not limiting to first line
    PatientWholeTabletsRemainingAndBrought.find(:all,                                              
      :joins => 
        "#{@@age_at_initiation_join_for_pills}  INNER JOIN patient_registration_dates \
           ON registration_date >= '#{@start_date.to_formatted_s}' AND registration_date <= '#{@end_date.to_formatted_s}' AND \
              patient_registration_dates.patient_id = patient_whole_tablets_remaining_and_brought.patient_id AND \
              patient_start_dates.age_at_initiation >= 15
        #{@outcome_join}",
      :conditions => ["visit_date >= ? AND visit_date <= ? AND total_remaining < 8 AND outcome_concept_id = ?", 
                      @start_date, @end_date, 324],      
      :group => "patient_whole_tablets_remaining_and_brought.patient_id").size
  end
  
  def death_dates
    first_month = PatientRegistrationDate.count(:include => [:patient], 
      :joins => "#{@outcome_join}",
      :conditions => [" \
      registration_date >= ? AND \
      registration_date <= ? AND \
      death_date >= registration_date AND \
      death_date < DATE_ADD(registration_date, INTERVAL 1 MONTH) AND \
      outcome_concept_id = ?", @start_date, @end_date, 322])

    second_month = PatientRegistrationDate.count(:include => [:patient], 
      :joins => "#{@outcome_join}",
      :conditions => [" \
      registration_date >= ? AND \
      registration_date <= ? AND \
      death_date >= DATE_ADD(registration_date, INTERVAL 1 MONTH) AND \
      death_date < DATE_ADD(registration_date, INTERVAL 2 MONTH) AND \
      outcome_concept_id = ?", 
      @start_date, @end_date, 322])

    third_month = PatientRegistrationDate.count(:include => [:patient], 
      :joins => "#{@outcome_join}",
      :conditions => [" \
      registration_date >= ? AND \
      registration_date <= ? AND \
      death_date >= DATE_ADD(registration_date, INTERVAL 2 MONTH) AND \
      death_date < DATE_ADD(registration_date, INTERVAL 3 MONTH) AND \
      outcome_concept_id = ?", @start_date, @end_date, 322])

    after_third_month = PatientRegistrationDate.count(:include => [:patient], 
      :joins => "#{@outcome_join}",
      :conditions => [" \
      registration_date >= ? AND \
      registration_date <= ? AND \
      death_date >= DATE_ADD(registration_date, INTERVAL 3 MONTH) AND \
      death_date IS NOT NULL AND \
      outcome_concept_id = ?", @start_date, @end_date, 322])
  
    [first_month, second_month, third_month, after_third_month]
  end

  def start_reasons
    patients = Patient.find(:all, 
                            :joins => "INNER JOIN patient_registration_dates ON \
                                       patient_registration_dates.patient_id = patient.patient_id",
                            :conditions => ["registration_date >= ? AND registration_date <= ?", 
                                             @start_date, @end_date])
    start_reasons = Hash.new(0)
    start_reasons["start_cause_EPTB"] = 0
    start_reasons["start_cause_PTB"] = 0
    start_reasons["start_cause_APTB"] = 0
    start_reasons["start_cause_KS"] = 0
    start_reasons["unknown_patient_ids"] = []
    patients.each{|patient|
      reason_for_art_eligibility = patient.reason_for_art_eligibility
      start_reason = reason_for_art_eligibility ? reason_for_art_eligibility.name : "Unknown"
      start_reason = 'WHO Stage 4' if start_reason == 'WHO stage 4 adult' or start_reason == 'WHO stage 4 peds'
      start_reason = 'WHO Stage 3' if start_reason == 'WHO stage 3 adult' or start_reason == 'WHO stage 3 peds'
      start_reasons[start_reason] += 1

      if start_reason == 'Unknown'
        number = patient.arv_number
        number = patient.national_id unless number
        start_reasons["unknown_patient_ids"] << number
      end

      next
      cohort_visit_data = patient.get_cohort_visit_data(@start_date, @end_date)                      
      if cohort_visit_data["Extrapulmonary tuberculosis (EPTB)"] == true
        start_reasons["start_cause_EPTB"] += 1
      elsif cohort_visit_data["PTB within the past 2 years"] == true
        start_reasons["start_cause_PTB"] += 1
      elsif cohort_visit_data["Active Pulmonary Tuberculosis"] == true 
        start_reasons["start_cause_APTB"] += 1
      end
      if cohort_visit_data["Kaposi's sarcoma"] == true
        start_reasons["start_cause_KS"] += 1
      end
      pmtct_obs = patient.observations.find_by_concept_name("Referred by PMTCT").last
      if pmtct_obs and pmtct_obs.value_coded == 3
        start_reasons["pmtct_pregnant_women_on_art"] +=1
      end
    }
    start_reasons
  end

  def regimen_types
    patients = Patient.find(:all,
      :joins => 
        "INNER JOIN patient_registration_dates ON patient_registration_dates.patient_id = patient.patient_id
         #{@outcome_join}",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND outcome_concept_id = ?", 
                      @start_date, @end_date, 324])

    regimen_types = Hash.new(0)
    regimen_breakdown = Hash.new(0)
    patients.each{|patient|
      regimen_type = patient.cohort_last_art_regimen(@start_date, @end_date)
      drug_code = patient.cohort_last_art_drug_code(@start_date, @end_date)
      if regimen_type
        regimen_types[regimen_type] += 1
        regimen_breakdown[drug_code] += 1
      else
        regimen_types['Unknown'] += 1
      end
    }
    [regimen_types, regimen_breakdown]
  end

  def old_outcomes
    patients = Patient.find(:all, 
                            :joins => "INNER JOIN patient_registration_dates ON \
                                       patient_registration_dates.patient_id = patient.patient_id",
                            :conditions => ["registration_date >= ? AND registration_date <= ?", 
                                             @start_date, @end_date])
    cohort_values = Hash.new(0)
    cohort_values['messages'] = []
    pat_ids = []
    patients.each{|patient|
      outcome_status = patient.cohort_outcome_status(@start_date, @end_date)
      
      if outcome_status == "Died" 
        cohort_values["dead_patients"] += 1
        pat_ids << patient.id
        unless patient.death_date.blank?
          art_start_date = patient.date_started_art
          death_date = patient.death_date
          mins_to_months = 60*60*24*7*4 # get 4 week months from minutes
          months_of_treatment = 0
          months_of_treatment = ((death_date.to_time - art_start_date.to_time)/mins_to_months).ceil unless art_start_date.nil?
          if months_of_treatment <= 1  
            cohort_values["died_1st_month"] += 1 
          elsif months_of_treatment == 2  
            cohort_values["died_2nd_month"] += 1
          elsif months_of_treatment == 3  
            cohort_values["died_3rd_month"] += 1
          elsif months_of_treatment > 3 
            cohort_values["died_after_3rd_month"] += 1
          end
        else
          cohort_values["messages"].push "Patient id #{self.id} has the outcome status 'Died' but no death date is set"  
        end  
      elsif outcome_status.include? "Transfer Out"
        cohort_values["transferred_out_patients"] += 1 
      elsif outcome_status == "ART Stop" 
        cohort_values["art_stopped_patients"] += 1  
      #elsif last_visit_datetime.nil? or (@quarter_end - last_visit_datetime.to_date).to_i > 90  
      #  cohort_values["defaulters"] += 1 
      elsif outcome_status == "Alive and on ART" || outcome_status == "On ART"
        cohort_values["alive_on_ART_patients"] += 1 
      end
    }
    cohort_values['pat_ids'] = pat_ids
    cohort_values
  end

  def survival_analysis(start_date=@start_date, end_date=@end_date, outcome_end_date=@end_date)
    date_ranges = Array.new
    # TODO: Remove magic number 3. Loop til the very first quarter
    (1..3).each{ |i|
      start_date = start_date.subtract_months(12)
      start_date -= start_date.day - 1
      end_date = end_date.subtract_months(12)
      date_ranges << {:start_date => start_date, :end_date => end_date}
    }

    survival_analysis_outcomes = Array.new

    date_ranges.each_with_index{|date_range, i|
      outcomes_hash = Hash.new(0)
      all_outcomes = self.outcomes(date_range[:start_date], date_range[:end_date], outcome_end_date)

      outcomes_hash["Title"] = "#{(i+1)*12} month survival: outcomes by end of #{outcome_end_date.strftime('%B %Y')}"
      outcomes_hash["Start Date"] = date_range[:start_date]
      outcomes_hash["End Date"] = date_range[:end_date]
      outcomes_hash["Total"] = all_outcomes.values.sum
      outcomes_hash["outcomes"] = all_outcomes
      
      survival_analysis_outcomes << outcomes_hash 
    }
    survival_analysis_outcomes
  end

private

  # Checking for the number of patients that have value as their most recent
  # observation for the given concept id
  def count_observations_for(concept_id, field = :value_coded, values = nil)
    values ||= [
      Concept.find_by_name("Yes").concept_id, 
      Concept.find_by_name("Yes drug induced").concept_id, 
      Concept.find_by_name("Yes not drug induced").concept_id, 
      Concept.find_by_name("Yes unknown cause").concept_id]
    PatientRegistrationDate.count(
      :joins => 
        "INNER JOIN ( \
          SELECT * FROM (
            SELECT * \
            FROM obs \
            WHERE obs_datetime >= '#{@start_date.to_formatted_s}' AND obs_datetime <= '#{@end_date.to_formatted_s}' AND \
              concept_id = #{concept_id} AND #{field} IN (#{values.join(',')}) \
            ORDER BY obs_datetime DESC \
          ) as t GROUP BY patient_id \
        ) as observation ON observation.patient_id = patient_registration_dates.patient_id
        
        INNER JOIN ( \
           SELECT * FROM ( \
             SELECT * \
             FROM patient_outcomes \
             WHERE outcome_date >= '#{@start_date.to_formatted_s}' AND outcome_date <= '#{@end_date.to_formatted_s}' \
             ORDER BY outcome_date DESC \
           ) as t GROUP BY patient_id \
        ) as outcome ON outcome.patient_id = patient_registration_dates.patient_id",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND outcome_concept_id = ?", @start_date, @end_date, 324])
  end
   
end
