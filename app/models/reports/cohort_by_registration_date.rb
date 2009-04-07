class Reports::CohortByRegistrationDate
  attr_accessor :start_date, :end_date
  @@age_at_initiation_join = 'INNER JOIN patient_start_dates ON patient_start_dates.patient_id = patient_registration_dates.patient_id'
  @@age_at_initiation_join_for_pills = 'INNER JOIN patient_start_dates ON patient_start_dates.patient_id = patient_whole_tablets_remaining_and_brought.patient_id'

  def initialize(start_date, end_date)
    @start_date = "#{start_date} 00:00:00"
    @end_date = "#{end_date} 23:59:59"

    # This find is difficult because you need to join in the outcomes, however
    # you want to get the most recent outcome for the period, meaning you have
    # to group and sort and filter all within the join
    @outcome_join = "INNER JOIN ( \
           SELECT * FROM ( \
             SELECT * \
             FROM patient_historical_outcomes \
             INNER JOIN ( \
               SELECT concept_id, 0 AS sort_weight FROM concept WHERE concept_id = 322 \
               UNION SELECT concept_id, 1 AS sort_weight FROM concept WHERE concept_id = 386 \
               UNION SELECT concept_id, 2 AS sort_weight FROM concept WHERE concept_id = 374 \
               UNION SELECT concept_id, 3 AS sort_weight FROM concept WHERE concept_id = 383 \
               UNION SELECT concept_id, 4 AS sort_weight FROM concept WHERE concept_id = 325 \
               UNION SELECT concept_id, 5 AS sort_weight FROM concept WHERE concept_id = 373 \
               UNION SELECT concept_id, 6 AS sort_weight FROM concept WHERE concept_id = 324 \
             ) AS ordered_outcomes ON ordered_outcomes.concept_id = patient_historical_outcomes.outcome_concept_id \
             WHERE outcome_date >= '#{@start_date}' AND outcome_date <= '#{@end_date}' \
             ORDER BY DATE(outcome_date) DESC, sort_weight \
           ) as t GROUP BY patient_id \
        ) as outcome ON outcome.patient_id = patient_registration_dates.patient_id"
  end

  def patients_started_on_arv_therapy
    PatientRegistrationDate.find(:all, :joins => @@age_at_initiation_join, :conditions => ["registration_date >= ? AND registration_date <= ?", @start_date, @end_date])
  end

  def men_started_on_arv_therapy
    # removed :include because it uses DISTINCT when passed to count. We don't want DISTINCT
    PatientRegistrationDate.find(:all, :joins => "INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id",
                                  :conditions => ["registration_date >= ? AND registration_date <= ? AND patient.gender = 'Male'", @start_date, @end_date])
  end

  def women_started_on_arv_therapy
    # removed :include because it uses DISTINCT when passed to count. We don't want DISTINCT
    PatientRegistrationDate.find(:all, :joins => "INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id",
                                  :conditions => ["registration_date >= ? AND registration_date <= ? AND patient.gender = 'Female'", @start_date, @end_date])
  end

  def pregnant_women
    PatientRegistrationDate.find(
      :all,
      :joins => "#{@@age_at_initiation_join} INNER JOIN obs ON obs.patient_id = patient_registration_dates.patient_id AND obs.voided = 0",
      :conditions => [
        'registration_date >= ? AND registration_date <= ? AND ((obs.concept_id = ?) OR (obs.concept_id = ? AND obs.value_coded = ?))',
        start_date, end_date, Concept.find_by_name('Referred by PMTCT').id,
        Concept.find_by_name('Pregnant').id,
        Concept.find_by_name('Yes').id
                    ],
      :group => 'patient_registration_dates.patient_id'
    ).map(&:patient)
  end

  def adults_started_on_arv_therapy
    PatientRegistrationDate.find(:all, :joins => "#{@@age_at_initiation_join} INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id", :conditions => ["registration_date >= ? AND registration_date <= ? AND TRUNCATE(DATEDIFF(start_date, birthdate)/365,1) >= ?", @start_date, @end_date, 15])
  end

  def children_started_on_arv_therapy
    PatientRegistrationDate.find(:all, :joins => "#{@@age_at_initiation_join} INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id",
                           :conditions => ["registration_date >= ? AND registration_date <= ? AND  TRUNCATE(DATEDIFF(start_date, birthdate)/365,1) >=  ? AND TRUNCATE(DATEDIFF(start_date, birthdate)/365,1) < ?",
                                           @start_date, @end_date, 1.5, 15])
  end

  def infants_started_on_arv_therapy
    PatientRegistrationDate.find(:all, :joins => "#{@@age_at_initiation_join} INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id",
                           :conditions => ["registration_date >= ? AND registration_date <= ? AND TRUNCATE(DATEDIFF(start_date, birthdate)/365,1) < ?",
                                           @start_date, @end_date, 1.5])
  end

  def transfer_ins_started_on_arv_therapy
    PatientRegistrationDate.find(:all, :joins => "#{@@age_at_initiation_join} INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id INNER JOIN obs ON obs.patient_id = patient.patient_id AND obs.voided = 0",
                           :conditions => ["registration_date >= ? AND registration_date <= ? AND obs.concept_id = ? AND value_coded = ?",
                                           @start_date, @end_date,
                                           Concept.find_by_name('Ever registered at ART clinic').id,
                                           Concept.find_by_name('Yes').id])
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
        identifier = 'business' if identifier =~ /business/ # TODO: do this for all other occupations
        identifier = 'healthcare worker' if identifier =~ /health|nurse|doctor|clinical officer|patient attendant/
        identifier = 'farmer' if identifier =~ /farmer/ # TODO: do this for all other occupations
        identifier = 'teacher' if identifier =~ /teacher/ # TODO: do this for all other occupations
        identifier = 'student' if identifier =~ /student|pupil/ # TODO: do this for all other occupations
        identifier = 'housewife' if identifier =~ /housewife/ # TODO: do this for all other occupations
        occupation_hash[identifier] += r.count.to_i

      }
    occupation_hash
  end

  def outcomes(start_date=@start_date, end_date=@end_date, outcome_end_date=@end_date, min_age=nil, max_age=nil)
    start_date = "#{start_date} 00:00:00" unless start_date == @start_date
    end_date = "#{end_date} 23:59:59" unless end_date == @end_date
    outcome_end_date = "#{outcome_end_date} 23:59:59" unless outcome_end_date == @end_date

    outcome_hash = Hash.new(0)
    conditions = ["registration_date >= ? AND registration_date <= ?", start_date, end_date]
    if min_age or max_age
      min_age ||= 0
      max_age ||= 999
      conditions = ["registration_date >= ? AND registration_date <= ? AND
                     TRUNCATE(DATEDIFF(start_date, birthdate)/365,1) >= ? AND
                     TRUNCATE(DATEDIFF(start_date, birthdate)/365,1) <= ?",
                     start_date, end_date, min_age, max_age]
    end
    # This find is difficult because you need to join in the outcomes, however
    # you want to get the most recent outcome for the period, meaning you have
    # to group and sort and filter all within the join
    reg_dates = PatientRegistrationDate.find(:all,
      :joins => "#{@outcome_join} #{@@age_at_initiation_join} INNER JOIN patient ON patient.patient_id = patient_start_dates.patient_id",
      :conditions => conditions,
      :group => "outcome_concept_id",
      :select => "outcome_concept_id, count(*) as count")
    reg_dates.map do |r|
      id = r.outcome_concept_id.to_i
      outcome_hash[id] = r.count.to_i
    end
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
    patient_reg_dates = PatientRegistrationDate.find(:all,
      :joins =>
        "LEFT JOIN ( \
            SELECT * FROM ( \
              SELECT patient_regimens.regimen_concept_id, patient_regimens.patient_id AS pid \
              FROM patient_regimens \
              WHERE dispensed_date >= '#{@start_date}' AND dispensed_date <= '#{@end_date}' \
              ORDER BY dispensed_date DESC \
            ) as ordered_regimens \
            GROUP BY ordered_regimens.pid \
         ) as last_regimen ON last_regimen.pid = patient_registration_dates.patient_id \
        #{@outcome_join}",

      :conditions => ["registration_date >= ? AND registration_date <= ? AND outcome_concept_id = ?", 
                      @start_date, @end_date, 324],
      :group => "regimen_concept_id",
      :select => "regimen_concept_id, count(*) as count")

    patient_reg_dates.map do |r|
      regimen_hash[r.regimen_concept_id.to_i] = r.count.to_i
    end
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
      side_effects_hash[concept_id] = count_last_observations_for([concept_id])
    }

    total_side_effects =
      ["Peripheral neuropathy",
       "Hepatitis",
       "Skin rash"].map {|symptom|
        concept_id = Concept.find_by_name(symptom).id
      }

    side_effects_hash['side_effects_patients_ever'] = count_observations_for(total_side_effects)
    side_effects_hash['side_effects_patients'] = count_last_observations_for(total_side_effects)
    side_effects_hash
  end

  # Adults on 1st line regimen with pill count done in the last month of the quarter
  # We implement this as last month of treatment in this period
  # Later join this so it is first line reg

   def adults_on_first_line_with_pill_count
    ## TODO, not limiting to first line
     Patient.find(:all,
      :joins =>
        "INNER JOIN patient_whole_tablets_remaining_and_brought ON patient_whole_tablets_remaining_and_brought.patient_id = patient.patient_id
  #{@@age_at_initiation_join_for_pills}  INNER JOIN patient_registration_dates \
           ON registration_date >= '#{@start_date}' AND registration_date <= '#{@end_date}' AND \
              patient_registration_dates.patient_id = patient_whole_tablets_remaining_and_brought.patient_id AND \
              patient_start_dates.age_at_initiation >= 15

        #{@outcome_join}",
      :conditions => ["visit_date >= ? AND visit_date <= ? AND outcome_concept_id = ?", @start_date, @end_date, 324],
      :group => "patient_whole_tablets_remaining_and_brought.patient_id")
  end

  # With pill count in the last month of the quarter at 8 or less

  def adults_on_first_line_with_pill_count_with_eight_or_less
    ## TODO, not limiting to first line
    Patient.find(:all,
      :joins =>
        "INNER JOIN patient_whole_tablets_remaining_and_brought \
          ON patient_whole_tablets_remaining_and_brought.patient_id = patient.patient_id
        #{@@age_at_initiation_join_for_pills}  INNER JOIN patient_registration_dates \
           ON registration_date >= '#{@start_date}' AND registration_date <= '#{@end_date}' AND \
              patient_registration_dates.patient_id = patient_whole_tablets_remaining_and_brought.patient_id AND \
              patient_start_dates.age_at_initiation >= 15
        #{@outcome_join}",
      :conditions => ["visit_date >= ? AND visit_date <= ? AND total_remaining < 8 AND outcome_concept_id = ?",
                      @start_date, @end_date, 324],
      :group => "patient_whole_tablets_remaining_and_brought.patient_id")
  end

  def death_dates
    # Removed this from first month because some people died before they were registered at LLH and MPC
    # outcome_date >= registration_date AND
    first_month = PatientRegistrationDate.count(:include => [:patient],
      :joins => "#{@outcome_join}",
      :conditions => [" \
      registration_date >= ? AND \
      registration_date <= ? AND \
      outcome_date < DATE_ADD(registration_date, INTERVAL 1 MONTH) AND \
      outcome_concept_id = ?", @start_date, @end_date, 322])

    second_month = PatientRegistrationDate.count(:include => [:patient],
      :joins => "#{@outcome_join}",
      :conditions => [" \
      registration_date >= ? AND \
      registration_date <= ? AND \
      outcome_date >= DATE_ADD(registration_date, INTERVAL 1 MONTH) AND \
      outcome_date < DATE_ADD(registration_date, INTERVAL 2 MONTH) AND \
      outcome_concept_id = ?",
      @start_date, @end_date, 322])

    third_month = PatientRegistrationDate.count(:include => [:patient],
      :joins => "#{@outcome_join}",
      :conditions => [" \
      registration_date >= ? AND \
      registration_date <= ? AND \
      outcome_date >= DATE_ADD(registration_date, INTERVAL 2 MONTH) AND \
      outcome_date < DATE_ADD(registration_date, INTERVAL 3 MONTH) AND \
      outcome_concept_id = ?", @start_date, @end_date, 322])

    after_third_month = PatientRegistrationDate.count(:include => [:patient],
      :joins => "#{@outcome_join}",
      :conditions => [" \
      registration_date >= ? AND \
      registration_date <= ? AND \
      outcome_date >= DATE_ADD(registration_date, INTERVAL 3 MONTH) AND \
      outcome_date IS NOT NULL AND \
      outcome_concept_id = ?", @start_date, @end_date, 322])

    [first_month, second_month, third_month, after_third_month]
  end

  def find_all_dead_patients(field)
    # Removed this from first month because some people died before they were registered at LLH and MPC
    # outcome_date >= registration_date AND
    if field == 'died_1st_month'
      dead_patients_list = Patient.find(:all,
        :joins => "INNER JOIN patient_registration_dates ON patient_registration_dates.patient_id = patient.patient_id #{@outcome_join}",
        :conditions => [" \
        registration_date >= ? AND \
        registration_date <= ? AND \
        outcome_date < DATE_ADD(registration_date, INTERVAL 1 MONTH) AND \
        outcome_concept_id = ?", @start_date, @end_date, 322])
    elsif field == 'died_2nd_month'
      dead_patients_list = Patient.find(:all,
        :joins => " INNER JOIN patient_registration_dates ON patient_registration_dates.patient_id = patient.patient_id #{@outcome_join}",
        :conditions => [" \
        registration_date >= ? AND \
        registration_date <= ? AND \
        outcome_date >= DATE_ADD(registration_date, INTERVAL 1 MONTH) AND \
        outcome_date < DATE_ADD(registration_date, INTERVAL 2 MONTH) AND \
        outcome_concept_id = ?",
        @start_date, @end_date, 322])
    elsif field == 'died_3rd_month'
      dead_patients_list = Patient.find(:all,
        :joins => "INNER JOIN patient_registration_dates ON patient_registration_dates.patient_id = patient.patient_id #{@outcome_join}",
        :conditions => [" \
        registration_date >= ? AND \
        registration_date <= ? AND \
        outcome_date >= DATE_ADD(registration_date, INTERVAL 2 MONTH) AND \
        outcome_date < DATE_ADD(registration_date, INTERVAL 3 MONTH) AND \
        outcome_concept_id = ?", @start_date, @end_date, 322])
    elsif field == 'died_after_3rd_month'
      dead_patients_list = Patient.find(:all,
        :joins => "INNER JOIN patient_registration_dates ON patient_registration_dates.patient_id = patient.patient_id #{@outcome_join}",
        :conditions => [" \
        registration_date >= ? AND \
        registration_date <= ? AND \
        outcome_date >= DATE_ADD(registration_date, INTERVAL 3 MONTH) AND \
        outcome_date IS NOT NULL AND \
        outcome_concept_id = ?", @start_date, @end_date, 322])
    end
    dead_patients_list
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

    @start_reason_patient_ids = Hash.new

    patients.each{|patient|
      reason_for_art_eligibility = patient.reason_for_art_eligibility
      start_reason = reason_for_art_eligibility ? reason_for_art_eligibility.name : "Other"

      start_reason = 'WHO Stage 4' if start_reason == 'WHO stage 4 adult' or start_reason == 'WHO stage 4 peds'
      start_reason = 'WHO Stage 3' if start_reason == 'WHO stage 3 adult' or start_reason == 'WHO stage 3 peds'

      start_reasons[start_reason] += 1
      load_start_reason_patient(start_reason, patient.id)

      cohort_visit_data = patient.get_cohort_visit_data(@start_date.to_date, @end_date.to_date)
      if cohort_visit_data["Extrapulmonary tuberculosis (EPTB)"] == true
        start_reasons["start_cause_EPTB"] += 1
        load_start_reason_patient('start_cause_EPTB', patient.id)
      elsif cohort_visit_data["PTB within the past 2 years"] == true
        start_reasons["start_cause_PTB"] += 1
        load_start_reason_patient('start_cause_PTB', patient.id)
      elsif cohort_visit_data["Active Pulmonary Tuberculosis"] == true
        start_reasons["start_cause_APTB"] += 1
        load_start_reason_patient('start_cause_APTB', patient.id)
      end
      if cohort_visit_data["Kaposi's sarcoma"] == true
        start_reasons["start_cause_KS"] += 1
        load_start_reason_patient('start_cause_KS', patient.id)
      end
      pmtct_obs = patient.observations.find_by_concept_name("Referred by PMTCT").last
      if pmtct_obs and pmtct_obs.value_coded == 3
        start_reasons["pmtct_pregnant_women_on_art"] +=1
        load_start_reason_patient('pmtct_pregnant_women_on_art', patient.id)
      end
    }
    [start_reasons, @start_reason_patient_ids]
  end

  def regimen_types
    patients = Patient.find(:all,
      :joins =>
        "INNER JOIN patient_registration_dates ON patient_registration_dates.patient_id = patient.patient_id
         #{@outcome_join}",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND outcome_concept_id = ?",
                      @start_date, @end_date, 324])

    alt_first_line_regimens = Hash.new(0)
    regimen_types = Hash.new(0)
    regimen_breakdown = Hash.new(0)
    patients.each{|patient|
      regimen_type = patient.cohort_last_art_regimen(@start_date, @end_date)
      drug_code = patient.cohort_last_art_drug_code(@start_date, @end_date)
      if regimen_type
        regimen_types[regimen_type] += 1
        regimen_breakdown[drug_code] += 1
        alt_first_line_regimens[drug_code.upcase] += 1 if regimen_type == "ARV First line regimen alternatives"
      else
        regimen_types['Unknown'] += 1
      end
    }
    [regimen_types, regimen_breakdown, alt_first_line_regimens]
  end

   def find_all_patient_art_regimens(regimen)
    patients = Patient.find(:all,
                            :joins => "INNER JOIN patient_registration_dates ON \
                                       patient_registration_dates.patient_id = patient.patient_id",
                            :conditions => ["registration_date >= ? AND registration_date <= ?",
                                             @start_date, @end_date])
    patient_ids = []
    patients.each{|patient|
      patient_ids << Patient.find(patient.id) if (patient.cohort_last_art_regimen == regimen) rescue nil
      }
    patient_ids
   end

  def survival_analysis(start_date=@start_date, end_date=@end_date, outcome_end_date=@end_date)
    # Make sure these are always dates
    start_date = start_date.to_date
    end_date = end_date.to_date
    outcome_end_date = outcome_end_date.to_date

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

  # Debugger
  def patients_with_occupations(occupations)
    occupation_id = PatientIdentifierType.find_by_name("Occupation").patient_identifier_type_id
    Patient.find(:all,
      :joins => "INNER JOIN patient_registration_dates ON patient_registration_dates.patient_id = patient.patient_id
        INNER JOIN patient_identifier ON \
           patient_identifier.patient_id = patient_registration_dates.patient_id AND \
           patient_identifier.voided = 0 AND \
           patient_identifier.identifier_type = #{occupation_id}",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND identifier IN (?)",
                       @start_date, @end_date, occupations],
      :order => "patient_identifier.date_created DESC")
  end

  def patients_with_outcomes(outcomes)
    concept_ids = outcomes.map{|name| Concept.find_by_name(name) ? Concept.find_by_name(name).id : nil }.compact
     Patient.find(:all,
      :joins => "INNER JOIN patient_registration_dates ON patient_registration_dates.patient_id = patient.patient_id
                 INNER JOIN patient_historical_outcomes ON patient_historical_outcomes.patient_id = patient.patient_id
                 #{@outcome_join}",
      :conditions => ['registration_date >= ? AND registration_date <= ?
                       AND patient_historical_outcomes.outcome_concept_id IN (?)
                       AND patient_historical_outcomes.outcome_date >= ?
                       AND patient_historical_outcomes.outcome_date <= ?',
                       start_date, end_date, concept_ids, start_date, end_date],
      :group => 'patient.patient_id', :order => 'patient_id'
    )
  end

  def find_patients_with_last_observation(concepts, field = :value_coded, values = nil)
    values ||= [
      Concept.find_by_name("Yes").concept_id,
      Concept.find_by_name("Yes drug induced").concept_id,
      Concept.find_by_name("Yes not drug induced").concept_id,
      Concept.find_by_name("Yes unknown cause").concept_id]
    Patient.find(:all,
      :joins =>
        "INNER JOIN patient_registration_dates ON patient_registration_dates.patient_id = patient.patient_id
         INNER JOIN ( \
          SELECT * FROM ( \
            SELECT * \
            FROM obs \
            INNER JOIN ( \
              SELECT * FROM ( \
                SELECT encounter.encounter_id AS eid, encounter.patient_id AS pid \
                FROM encounter \
                WHERE encounter_datetime >= '#{@start_date}' AND encounter_datetime <= '#{@end_date}' AND encounter_type = 2 \
                ORDER BY encounter_datetime DESC \
              ) as ordered_encounters \
              GROUP BY ordered_encounters.pid \
            ) as last_encounter ON last_encounter.eid = obs.encounter_id \
            WHERE obs_datetime >= '#{@start_date}' AND obs_datetime <= '#{@end_date}' AND \
              concept_id IN (#{concepts.join(',')}) AND #{field} IN (#{values.join(',')}) \
            ORDER BY obs_datetime DESC \
          ) as t GROUP BY patient_id \
        ) as observation ON observation.patient_id = patient_registration_dates.patient_id \

        #{@outcome_join}",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND outcome_concept_id = ?", @start_date, @end_date, 324])
  end

private

  # Checking for the number of patients that have value as their most recent
  # observation for the given set of concept ids
  def count_observations_for(concepts, field = :value_coded, values = nil)
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
            WHERE obs_datetime >= '#{@start_date}' AND obs_datetime <= '#{@end_date}' AND \
              concept_id IN (#{concepts.join(',')}) AND #{field} IN (#{values.join(',')}) \
            ORDER BY obs_datetime DESC \
          ) as t GROUP BY patient_id \
        ) as observation ON observation.patient_id = patient_registration_dates.patient_id

        #{@outcome_join}",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND outcome_concept_id = ?", @start_date, @end_date, 324])
  end

  # Checking for the number of patients that have value as their most recent
  # observation for the given set of concept ids
  def count_last_observations_for(concepts, field = :value_coded, values = nil)
    self.find_patients_with_last_observation(concepts, field, values).length
  end


  def load_start_reason_patient(reason, patient_id)
    @start_reason_patient_ids[reason] = [] unless @start_reason_patient_ids[reason]
    @start_reason_patient_ids[reason] << patient_id
  end

end
