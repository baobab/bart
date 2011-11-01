# == Reports::CohortByRegistrationDate -- Methods for generating Cohort Reports
#
# Retrieves patients that are tallied for each Cohort Report element
# 
# All methods return +PatientRegistrationDate+ objects unless otherwise specified
#
# ==== Example
#
# <tt>report = Reports::CohortByRegistraitonDate.new('2010-01-01',
#   '2010-03-31')</tt>
#
# <tt>report.patients_on_arv_therapy.length')</tt>
#


class Reports::CohortByRegistrationDate
   
  attr_accessor :start_date, :end_date
  @@age_at_initiation_join = 'INNER JOIN patient_start_dates ON
    patient_start_dates.patient_id = patient_registration_dates.patient_id'
  @@age_at_initiation_join_for_pills = 'INNER JOIN patient_start_dates ON 
    patient_start_dates.patient_id =
      patient_whole_tablets_remaining_and_brought.patient_id'
  
  @@arv_code = Location.current_arv_code
  @@foreign_patients_join = "INNER JOIN patient p2 ON
    p2.patient_id = patient_registration_dates.patient_id AND NOT EXISTS (
      SELECT * FROM patient_identifier
      WHERE patient_identifier.patient_id =
            patient_registration_dates.patient_id AND identifier_type=18
            AND LEFT(identifier,#{@@arv_code.length}) != '#{@@arv_code}' AND
            patient_identifier.voided = 0)"

  # Initializer. Use Reports::CohortByRegistration.new()
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
               UNION SELECT concept_id, 1 AS sort_weight FROM concept WHERE concept_id = 374 \
               UNION SELECT concept_id, 2 AS sort_weight FROM concept WHERE concept_id = 383 \
               UNION SELECT concept_id, 3 AS sort_weight FROM concept WHERE concept_id = 325 \
               UNION SELECT concept_id, 4 AS sort_weight FROM concept WHERE concept_id = 386 \
               UNION SELECT concept_id, 5 AS sort_weight FROM concept WHERE concept_id = 373 \
               UNION SELECT concept_id, 6 AS sort_weight FROM concept WHERE concept_id = 324 \
             ) AS ordered_outcomes ON ordered_outcomes.concept_id = patient_historical_outcomes.outcome_concept_id \
             WHERE outcome_date >= '#{@start_date}' AND outcome_date <= '#{@end_date}' \
             ORDER BY DATE(outcome_date) DESC, sort_weight \
           ) as t GROUP BY patient_id \
        ) as outcome ON outcome.patient_id = patient_registration_dates.patient_id
        #{@@foreign_patients_join}"
  end

  # Patients whose registration date falls within the specified reporting period
  def patients_started_on_arv_therapy(min_age=nil, max_age=nil)
    conditions = ["registration_date >= ? AND registration_date <= ?",
                                                 @start_date, @end_date]
    conditions = ["registration_date >= ? AND registration_date <= ? AND age_at_initiation >= ? AND age_at_initiation <= ?",
                                                 @start_date, @end_date, min_age, max_age] if min_age and max_age
    PatientRegistrationDate.find(:all, :joins => @@age_at_initiation_join, 
                               :conditions => conditions)
  end

  # Male patients whose registration date falls within the specified reporting
  # period
  def men_started_on_arv_therapy
    PatientRegistrationDate.find(:all, 
      :joins => "#{@@age_at_initiation_join}
        INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND
                       patient.gender = 'Male'", @start_date, @end_date])
  end

  # Female patients whose registration date falls within the specified reporting
  # period
  def women_started_on_arv_therapy
    PatientRegistrationDate.find(:all, 
      :joins => "#{@@age_at_initiation_join}
        INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND
                       patient.gender = 'Female'", @start_date, @end_date])
  end

   # Patients who were Pregnant within 30 days of starting ART. Includes patients
   # <tt>Referred by PMTCT</tt> for non-Lighthouse sites
   def pregnant_women
    if ['LLH','MPC'].include? @@arv_code
      PatientRegistrationDate.find(:all,
                                 :joins => "#{@@age_at_initiation_join} INNER JOIN obs ON obs.patient_id = patient_registration_dates.patient_id AND obs.voided = 0",
                                 :conditions => ['registration_date >= ? AND registration_date <= ? AND (
                                                 (obs.concept_id = ? AND obs.value_coded = ? AND (DATEDIFF(DATE(obs.obs_datetime), start_date) >= ?) AND DATEDIFF(DATE(obs.obs_datetime), start_date) <= ?))',
                                                 @start_date, @end_date,
                                                 Concept.find_by_name('Pregnant').id,
                                                 Concept.find_by_name('Yes').id, 0, 30
                                                ],
                                 :group => 'patient_registration_dates.patient_id'
                                )
    else
      PatientRegistrationDate.find(:all,
                                 :joins => "#{@@age_at_initiation_join} INNER JOIN obs ON obs.patient_id = patient_registration_dates.patient_id AND obs.voided = 0",
                                 :conditions => ['registration_date >= ? AND registration_date <= ? AND ((obs.concept_id = ? AND obs.value_coded = ? ) OR
                                                 (obs.concept_id = ? AND obs.value_coded = ? AND (DATEDIFF(DATE(obs.obs_datetime), start_date) >= ?) AND DATEDIFF(DATE(obs.obs_datetime), start_date) <= ?))',
                                                 @start_date, @end_date,
                                                 Concept.find_by_name('Referred by PMTCT').id,
                                                 Concept.find_by_name('Yes').id,
                                                 Concept.find_by_name('Pregnant').id,
                                                 Concept.find_by_name('Yes').id, 0, 30
                                                ],
                                 :group => 'patient_registration_dates.patient_id'
                                )
    end

  end


  # Female patients who are not pregnant. See <tt>pregnant_women</tt> for more information
  def non_pregnant_women
    self.women_started_on_arv_therapy - self.pregnant_women
  end

  # Patients who started ART when they were aged 15 or over
  # TODO: use +age+ function inorder to better accomodate estimated dates
  def adults_started_on_arv_therapy
    #PatientRegistrationDate.find(:all, :joins => @@age_at_initiation_join, :conditions => ["registration_date >= ? AND registration_date <= ? AND age_at_initiation >= ?", @start_date, @end_date, 15])
    PatientRegistrationDate.find(:all,
      :joins => "#{@@age_at_initiation_join}
        INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND
                       TRUNCATE(DATEDIFF(start_date, patient.birthdate)/365,0) >= ?",
                      @start_date, @end_date, 15])
  end

  # Patients who started ART when they were aged between the specified
  # <tt>min_age</tt> and <tt>max_age</tt>
  def children_started_on_arv_therapy(min_age=2, max_age=14)
    PatientRegistrationDate.find(:all, :joins => "#{@@age_at_initiation_join} INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id", 
                           :conditions => ["registration_date >= ? AND registration_date <= ? AND  TRUNCATE(DATEDIFF(start_date, patient.birthdate)/365,1) >=  ? AND TRUNCATE(DATEDIFF(start_date, patient.birthdate)/365,0) < ?",
                                           @start_date, @end_date,min_age, max_age+1])
  end

  # Patients who started ART when they were under 1.5 years of age
  #
  # Return +PatientRegistrationDate+ objects
  def infants_started_on_arv_therapy
    PatientRegistrationDate.find(:all, :joins => "#{@@age_at_initiation_join} INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id", 
                           :conditions => ["registration_date >= ? AND registration_date <= ? AND TRUNCATE(DATEDIFF(start_date, patient.birthdate)/365,1) < ?",
                                           @start_date, @end_date, 2])
  end

  # Patients who started ART at a different clinic from this one excluding those
  # who are re-initiations
  #
  # Uses <tt>Ever registered at ART clinic</tt> observations
  def transfer_ins_started_on_arv_therapy
    PatientRegistrationDate.find(:all, :joins => "#{@@age_at_initiation_join} INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id INNER JOIN obs ON obs.patient_id = patient.patient_id AND obs.voided = 0", 
                           :conditions => ["registration_date >= ? AND registration_date <= ? AND obs.concept_id = ? AND value_coded = ?", 
                                           @start_date, @end_date, 
                                           Concept.find_by_name('Ever registered at ART clinic').id, 
                                           Concept.find_by_name('Yes').id],
			   :group => 'patient_id') - self.re_initiated_patients
  end

  # Patients who did not transfer into current clinic.
  #
  # See <tt>transfer_ins_started_on_arv_therapy</tt> for more information
  def new_patients
    self.patients_started_on_arv_therapy - self.transfer_ins_started_on_arv_therapy
  end

  def occupations #:nodoc:
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


  # Number of patients per +PatientOutcome+ status
  def outcomes(start_date=@start_date, end_date=@end_date, outcome_end_date=@end_date, min_age=nil, max_age=nil)
    start_date = "#{start_date} 00:00:00" unless start_date == @start_date
    end_date = "#{end_date} 23:59:59" unless end_date == @end_date
    outcome_end_date = "#{outcome_end_date} 23:59:59" unless outcome_end_date == @end_date

    outcome_hash = Hash.new(0)
    conditions = ["registration_date >= ? AND registration_date <= ?", start_date, end_date]
    if min_age or max_age
      min_age = 0 unless min_age
      max_age = 999 unless max_age # TODO: Should this be something like MAX(age_at_initiation) ?
      conditions = ["registration_date >= ? AND registration_date <= ? AND 
                     TRUNCATE(DATEDIFF(start_date, patient.birthdate)/365,0) >= ? AND
                     TRUNCATE(DATEDIFF(start_date, patient.birthdate)/365,0) <= ?",
                     start_date, end_date, min_age, max_age]
    end
    # This find is difficult because you need to join in the outcomes, however
    # you want to get the most recent outcome for the period, meaning you have
    # to group and sort and filter all within the join
    #
    # This is a self.outcomes specific outcome_join to use Start and Outcome End Dates
    # from Survival Analysis and excludes @@foreign_outcome_join which is not
    # required in self.outcomes_for_foreign_patients
    outcome_join = "INNER JOIN ( \
           SELECT * FROM ( \
             SELECT * \
             FROM patient_historical_outcomes \
             INNER JOIN ( \
               SELECT concept_id, 0 AS sort_weight FROM concept WHERE concept_id = 322 \
               UNION SELECT concept_id, 1 AS sort_weight FROM concept WHERE concept_id = 374 \
               UNION SELECT concept_id, 2 AS sort_weight FROM concept WHERE concept_id = 383 \
               UNION SELECT concept_id, 3 AS sort_weight FROM concept WHERE concept_id = 325 \
               UNION SELECT concept_id, 4 AS sort_weight FROM concept WHERE concept_id = 386 \
               UNION SELECT concept_id, 5 AS sort_weight FROM concept WHERE concept_id = 373 \
               UNION SELECT concept_id, 6 AS sort_weight FROM concept WHERE concept_id = 324 \
             ) AS ordered_outcomes ON ordered_outcomes.concept_id = patient_historical_outcomes.outcome_concept_id \
             WHERE outcome_date >= '#{start_date}' AND outcome_date <= '#{outcome_end_date}' \
             ORDER BY DATE(outcome_date) DESC, sort_weight \
           ) as t GROUP BY patient_id \
        ) as outcome ON outcome.patient_id = patient_registration_dates.patient_id"

    # The @@foreign_patients join has been excluded in the above outcome_join in
    # order to include @@foreign_patients when we pass outcome_join to
    # self.outcomes_for_foreign_patients below
    PatientRegistrationDate.find(:all,
      :joins => "#{outcome_join}
        #{@@foreign_patients_join}
        #{@@age_at_initiation_join}
        INNER JOIN patient ON patient.patient_id =
                              patient_start_dates.patient_id",
      :conditions => conditions,
      :group => "outcome_concept_id",
      :select => "outcome_concept_id, count(*) as count").map do |r|
        outcome_hash[r.outcome_concept_id.to_i] = r.count.to_i
      end

    # Count 'foreign patients' as Transfer out patients
    # self.outcomes_for_foreign_patients below
    outcome_hash[325] += self.outcomes_for_foreign_patients(
                           outcome_join,
                           conditions
                         ).values.sum
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
        "LEFT JOIN ( \
            SELECT * FROM ( \
              SELECT patient_historical_regimens.regimen_concept_id, 
              patient_historical_regimens.patient_id AS pid,
              patient_historical_regimens.category \
              FROM patient_historical_regimens \
              WHERE dispensed_date >= '#{@start_date}' AND dispensed_date <= '#{@end_date}' \
              ORDER BY dispensed_date DESC \
            ) as ordered_regimens \
            GROUP BY ordered_regimens.pid \
         ) as last_regimen ON last_regimen.pid = patient_registration_dates.patient_id \
        
        #{@outcome_join} #{@@age_at_initiation_join}",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND outcome_concept_id = ?", @start_date, @end_date, 324],
      :group => "last_regimen.category",
      :select => "last_regimen.category, count(*) as count").map {|r| regimen_hash[r.category] = r.count.to_i }
    regimen_hash
  end

  def regimen_type(category)
    on_art_concept_id = Concept.find_by_name("On ART").id
    regimen_hash = Hash.new()
    # This find is difficult because you need to join in the outcomes and 
    # regimens, however you want to get the most recent outcome or regimen for 
    # the period, meaning you have to group and sort and filter all within the 
    # join. We use a left join for regimens so that unknown regimens show as 
    # NULL. 
    PatientRegistrationDate.find(:all,
      :joins => 
        "LEFT JOIN ( \
            SELECT * FROM ( \
              SELECT patient_historical_regimens.regimen_concept_id, 
              patient_historical_regimens.patient_id AS pid,
              patient_historical_regimens.category \
              FROM patient_historical_regimens \
              WHERE dispensed_date >= '#{@start_date}' AND dispensed_date <= '#{@end_date}' \
              ORDER BY dispensed_date DESC \
            ) as ordered_regimens \
            GROUP BY ordered_regimens.pid \
         ) as last_regimen ON last_regimen.pid = patient_registration_dates.patient_id \
        
        #{@outcome_join} #{@@age_at_initiation_join}",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND outcome_concept_id = ?", @start_date, @end_date, 324],
      :select => "last_regimen.category, last_regimen.pid as pat_id").map do |r| 
        regimen_hash[r.category] = [] if regimen_hash[r.category].blank?
        regimen_hash[r.category] << r.pat_id 
      end
    if category == 'other_regimen'
      regimen_hash.each do |regimen , patient_ids |
        next unless regimen.blank?
        return patient_ids
      end
    end
    regimen_hash[category]
  end

  def side_effects
    side_effects_hash = {}
    [
#     "Is able to walk unaided",
#     "Is at work/school",
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
       "Leg pain / numbness",
       "Hepatitis", 
       "Jaundice",
       "Skin rash"].map {|symptom|  
        concept_id = Concept.find_by_name(symptom).id 
      }
       
    side_effects_hash['side_effects_patients_ever'] = count_observations_for(total_side_effects)    
    side_effects_hash['side_effects_patients'] = count_last_observations_for(total_side_effects)    
    side_effects_hash    
  end

  def side_effect_patients
    find_patients_with_last_observation([91, 416, 92, 419, 93])
  end

  def transferred_out_patients(outcome_end_date=@end_date,min_age=nil, max_age=nil)
    if min_age and max_age
      patients_with_outcomes('Transfer out,Transfer Out(With Transfer Note),Transfer Out(Without Transfer Note)'.split(","),
                           outcome_end_date, min_age, max_age)
    else
      patients_with_outcomes('Transfer out,Transfer Out(With Transfer Note),Transfer Out(Without Transfer Note)'.split(","), outcome_end_date)
    end
  end

  def patients_with_dosses_missed(min, max=99999999999)
    PatientRegistrationDate.find(:all,
      :joins => "
      INNER JOIN patient_whole_tablets_remaining_and_brought pwt ON
                 pwt.patient_id = patient_registration_dates.patient_id
      INNER JOIN patient_adherence_rates par ON par.patient_id = pwt.patient_id AND
                 par.drug_id = pwt.drug_id AND
                 par.visit_date = pwt.previous_visit_date
      #{@outcome_join}  #{@@age_at_initiation_join}",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND
        pwt.visit_date = (
        SELECT MAX(pwt2.visit_date)
          FROM patient_whole_tablets_remaining_and_brought pwt2
          WHERE pwt2.patient_id = pwt.patient_id AND pwt2.visit_date <= ?
          GROUP BY pwt2.patient_id
        ) AND pwt.total_remaining - par.expected_remaining BETWEEN ? AND ? AND outcome_concept_id = ?",
        @start_date, @end_date, @end_date, min, max, 324],
      :group => "patient_id")
  end

  # Patients who missed up to 6 doses
  # Zero - 6 doses missed = 95 - 100% adherence
  def patients_with_few_dosses_missed
    self.adherent_patients
  end

  # Patients who missed more than 6 doses
  # See also: +patients_with_few_dosses_missed+
  def patients_with_more_dosses_missed
    self.under_adherent_patients + self.over_adherent_patients
  end
  
  # Adults on 1st line regimen with pill count done in the last month of the quarter
  # We implement this as last month of treatment in this period
  # Later join this so it is first line reg

   def adults_on_first_line_with_pill_count #:nodoc:
    ## TODO, not limiting to first line
     Patient.find(:all,                                              
      :joins => 
        "INNER JOIN patient_whole_tablets_remaining_and_brought ON patient_whole_tablets_remaining_and_brought.patient_id = patient.patient_id
	#{@@age_at_initiation_join_for_pills}  INNER JOIN patient_registration_dates \
           ON registration_date >= '#{@start_date}' AND registration_date <= '#{@end_date}' AND \
              patient_registration_dates.patient_id = patient_whole_tablets_remaining_and_brought.patient_id AND \
              patient_start_dates.age_at_initiation >= 15
         INNER JOIN patient_historical_regimens ON patient.patient_id = patient_historical_regimens.patient_id AND patient_historical_regimens.regimen_concept_id = 450 AND dispensed_date >= '#{@start_date}' AND dispensed_date <= '#{@end_date}' 
         
        #{@outcome_join}",
      :conditions => ["visit_date >= ? AND visit_date <= ? AND outcome_concept_id = ?", @start_date, @end_date, 324],      
      :group => "patient_whole_tablets_remaining_and_brought.patient_id")
  end

  # With pill count in the last month of the quarter at 8 or less

  def adults_on_first_line_with_pill_count_with_eight_or_less #:nodoc:
    ## TODO, not limiting to first line
    Patient.find(:all,                                              
      :joins => 
        "INNER JOIN patient_whole_tablets_remaining_and_brought \
          ON patient_whole_tablets_remaining_and_brought.patient_id = patient.patient_id
        #{@@age_at_initiation_join_for_pills}  INNER JOIN patient_registration_dates \
           ON registration_date >= '#{@start_date}' AND registration_date <= '#{@end_date}' AND \
              patient_registration_dates.patient_id = patient_whole_tablets_remaining_and_brought.patient_id AND \
              patient_start_dates.age_at_initiation >= 15
         INNER JOIN patient_historical_regimens ON patient.patient_id = patient_historical_regimens.patient_id AND patient_historical_regimens.regimen_concept_id = 450 AND dispensed_date >= '#{@start_date}' AND dispensed_date <= '#{@end_date}' 
        #{@outcome_join}",
      :conditions => ["visit_date >= ? AND visit_date <= ? AND total_remaining < 8 AND outcome_concept_id = ?", 
                      @start_date, @end_date, 324],      
      :group => "patient_whole_tablets_remaining_and_brought.patient_id",
      :select =>"patient_whole_tablets_remaining_and_brought.patient_id as pid, patient_whole_tablets_remaining_and_brought.visit_date as pdate")
  end

  def death_dates
    # Removed this from first month because some people died before they were registered at LLH and MPC
    # outcome_date >= registration_date AND 
    first_month = PatientRegistrationDate.count(:include => [:patient], 
      :joins => "#{@outcome_join} #{@@age_at_initiation_join}",
      :conditions => [" \
      registration_date >= ? AND \
      registration_date <= ? AND \
      outcome_date < DATE_ADD(registration_date, INTERVAL 1 MONTH) AND \
      outcome_concept_id = ?", @start_date, @end_date, 322])

    second_month = PatientRegistrationDate.count(:include => [:patient], 
      :joins => "#{@outcome_join} #{@@age_at_initiation_join}",
      :conditions => [" \
      registration_date >= ? AND \
      registration_date <= ? AND \
      outcome_date >= DATE_ADD(registration_date, INTERVAL 1 MONTH) AND \
      outcome_date < DATE_ADD(registration_date, INTERVAL 2 MONTH) AND \
      outcome_concept_id = ?", 
      @start_date, @end_date, 322])

    third_month = PatientRegistrationDate.count(:include => [:patient], 
      :joins => "#{@outcome_join} #{@@age_at_initiation_join}",
      :conditions => [" \
      registration_date >= ? AND \
      registration_date <= ? AND \
      outcome_date >= DATE_ADD(registration_date, INTERVAL 2 MONTH) AND \
      outcome_date < DATE_ADD(registration_date, INTERVAL 3 MONTH) AND \
      outcome_concept_id = ?", @start_date, @end_date, 322])

    after_third_month = PatientRegistrationDate.count(:include => [:patient], 
      :joins => "#{@outcome_join} #{@@age_at_initiation_join}",
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
      dead_patients_list = PatientRegistrationDate.find(:all,
        :joins => "INNER JOIN patient ON patient.patient_id =
                              patient_registration_dates.patient_id
                   #{@outcome_join} #{@@age_at_initiation_join}",
        :conditions => [" \
          registration_date >= ? AND \
          registration_date <= ? AND \
          outcome_date < DATE_ADD(registration_date, INTERVAL 1 MONTH) AND \
          outcome_concept_id = ?", @start_date, @end_date, 322])
    elsif field == 'died_2nd_month'
      dead_patients_list = PatientRegistrationDate.find(:all,
        :joins => " INNER JOIN patient ON patient.patient_id =
                              patient_registration_dates.patient_id
                   #{@outcome_join} #{@@age_at_initiation_join}",
        :conditions => [" \
        registration_date >= ? AND \
        registration_date <= ? AND \
        outcome_date >= DATE_ADD(registration_date, INTERVAL 1 MONTH) AND \
        outcome_date < DATE_ADD(registration_date, INTERVAL 2 MONTH) AND \
        outcome_concept_id = ?", 
        @start_date, @end_date, 322])
    elsif field == 'died_3rd_month'
      dead_patients_list = PatientRegistrationDate.find(:all,
        :joins => "INNER JOIN patient ON patient.patient_id =
                              patient_registration_dates.patient_id
                  #{@outcome_join} #{@@age_at_initiation_join}",
        :conditions => [" \
        registration_date >= ? AND \
        registration_date <= ? AND \
        outcome_date >= DATE_ADD(registration_date, INTERVAL 2 MONTH) AND \
        outcome_date < DATE_ADD(registration_date, INTERVAL 3 MONTH) AND \
        outcome_concept_id = ?", @start_date, @end_date, 322])
    elsif field == 'died_after_3rd_month'
      dead_patients_list = PatientRegistrationDate.find(:all,
        :joins => "INNER JOIN patient ON patient.patient_id =
                              patient_registration_dates.patient_id
                  #{@outcome_join} #{@@age_at_initiation_join}",
        :conditions => [" \
        registration_date >= ? AND \
        registration_date <= ? AND \
        outcome_date >= DATE_ADD(registration_date, INTERVAL 3 MONTH) AND \
        outcome_date IS NOT NULL AND \
        outcome_concept_id = ?", @start_date, @end_date, 322])
    end
    dead_patients_list
  end

  # Returns a hash map of number of patients against their corresponsing start
  # reasons and causes
  def start_reasons
    start_reason_hash = Hash.new(0)
    PatientRegistrationDate.find(:all, :select => 'value, COUNT(*) AS count',
#      :joins => "INNER JOIN person ON person.patient_id = patient_registration_dates.patient_id
#                 INNER JOIN person_attribute ON person_attribute.person_id = person.person_id",
      :joins => "INNER JOIN person_attribute ON person_attribute.person_id = patient_registration_dates.patient_id
                 INNER JOIN patient_start_dates ON patient_start_dates.patient_id = patient_registration_dates.patient_id",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND
                       person_attribute_type_id = ?", @start_date, @end_date, 1],
      :group => 'person_attribute.value'
    ).map do |r|
      r.value.gsub!(/\sadult|\speds/, "")
      start_reason_hash[r.value] += r.count.to_i
    end

    # avoid negatives
    start_reason_hash["Other"] = [(self.patients_started_on_arv_therapy.length - start_reason_hash.values.sum),0].max

    start_reason_hash["start_cause_EPTB"] = self.find_patients_with_staging_observation(
      [Concept.find_by_name("Extrapulmonary tuberculosis").id]).length
    start_reason_hash["start_cause_PTB"] = self.find_patients_with_staging_observation(
      [Concept.find_by_name("Pulmonary tuberculosis within the last 2 years").id]).length
    start_reason_hash["start_cause_APTB"] = self.find_patients_with_staging_observation(
      [Concept.find_by_name("Pulmonary tuberculosis (current)").id]).length
    start_reason_hash["start_cause_KS"] = self.find_patients_with_staging_observation(
      [Concept.find_by_name("Kaposi's sarcoma").id]).length

    [start_reason_hash, Hash.new(0)]
  end

  
  def start_reasons_old #:nodoc:
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
      # start_reason = 'Other' if start_reason == 'Lymphocyte count below threshold with WHO stage 2' 

      start_reason = 'WHO Stage 4' if start_reason == 'WHO stage 4 adult' or start_reason == 'WHO stage 4 peds'
      start_reason = 'WHO Stage 3' if start_reason == 'WHO stage 3 adult' or start_reason == 'WHO stage 3 peds'
 
      start_reasons[start_reason] += 1
      load_start_reason_patient(start_reason, patient.id)

      cohort_visit_data = patient.get_cohort_visit_data(@start_date.to_date, @end_date.to_date)  
      if cohort_visit_data["Extrapulmonary tuberculosis"] == true
        start_reasons["start_cause_EPTB"] += 1
        load_start_reason_patient('start_cause_TB', patient.id)
      elsif cohort_visit_data["Pulmonary tuberculosis within the last 2 years"] == true
        start_reasons["start_cause_PTB"] += 1
        load_start_reason_patient('start_cause_TB', patient.id)
      elsif cohort_visit_data["Pulmonary tuberculosis (current)"] == true
        start_reasons["start_cause_APTB"] += 1
        load_start_reason_patient('start_cause_TB', patient.id)
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

  def patients_with_start_reason(reasons)

    reasons = [reasons] if reasons.class == String
    if reasons == ['who_stage_1_or_2_cd4']
      reasons = ['CD4 Count < 250','CD4 percentage < 25',
                 'CD4 Count < 350','CD4 Count < 750']
    elsif reasons == ['who_stage_2_lymphocyte']
      reasons = ['Lymphocyte count below threshold with WHO stage 2']
    elsif reasons == ['WHO stage 3']
      reasons = ['WHO stage 3 adult', 'WHO stage 3 peds']
    elsif reasons == ['WHO stage 4']
      reasons = ['WHO stage 4 adult', 'WHO stage 4 peds']
    end

    if reasons == ['Other']
      extra_join = ''
      reason_conditions = ['registration_date >= ? AND registration_date <= ? AND NOT EXISTS (
                        SELECT * FROM person_attribute
                        WHERE person_id = patient.patient_id AND person_attribute_type_id = 1)',
                      @start_date, @end_date]
    else
      extra_join = 'INNER JOIN person_attribute pa ON pa.person_id = patient.patient_id'
      reason_conditions = ['registration_date >= ? AND registration_date <= ? AND
                      person_attribute_type_id = 1 AND value IN (?)',
                      @start_date, @end_date, reasons]
    end
    PatientRegistrationDate.find(:all,
      :joins => "INNER JOIN patient ON patient.patient_id =
                              patient_registration_dates.patient_id
        INNER JOIN patient_start_dates ON patient_start_dates.patient_id =
                   patient.patient_id
        #{extra_join}",
      :conditions => reason_conditions,
      :group => 'patient.patient_id')

  end

  def patients_with_start_cause(cause)
    cause = "start_cause_KS" if cause == "Kaposi's sarcoma"
    concept_id = Concept.find_by_name(cause).id rescue nil
    if concept_id
      self.find_patients_with_staging_observation([concept_id])
    elsif cause == "start_cause_tb_within_two_years"
      self.find_patients_with_staging_observation(
      [Concept.find_by_name('Pulmonary tuberculosis within the last 2 years').id,
       Concept.find_by_name('Extrapulmonary tuberculosis').id])
    elsif cause == "start_cause_current_tb"
      self.find_patients_with_staging_observation(
      [Concept.find_by_name('Pulmonary tuberculosis (current)').id])
    elsif cause == "start_cause_no_tb"
      self.patients_started_on_arv_therapy -
        self.find_patients_with_staging_observation(
          [Concept.find_by_name('Pulmonary tuberculosis within the last 2 years').id,
          Concept.find_by_name('Extrapulmonary tuberculosis').id]) -
        self.find_patients_with_staging_observation(
          [Concept.find_by_name('Pulmonary tuberculosis (current)').id])
    elsif cause == "start_cause_KS"
      self.find_patients_with_staging_observation(
      [Concept.find_by_name("Kaposi's sarcoma").id])
    else
      []
    end
  end

  def regimen_types #:nodoc:
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
    patients = PatientRegistrationDate.find(:all,
      :joins => "INNER JOIN patient ON \
                 patient.patient_id = patient_registration_dates.patient_id
                 ",
      :conditions => ["registration_date >= ? AND registration_date <= ?",
                       @start_date, @end_date])

=begin
    patient_ids = []
    patients.each{|patient|
      patient_ids << Patient.find(patient.id) if (patient.cohort_last_art_regimen == regimen) rescue nil 
      }
=end
    patient_ids = patients.each{|p|p.patient_id}.compact.uniq rescue []
    patient_ids = PatientHistoricalRegimen.find(:all,:group => "patient_id",
        :conditions =>["patient_id IN (?) AND category = ? AND dispensed_date >= ?
        AND dispensed_date <= ?",patient_ids,regimen,@start_date , @end_date],
        :order => "dispensed_date DESC").collect{| r | r.patient_id } 
    patient_ids 
   end

   # Patients who were not suspected to have TB on their last ART Visit
   def tb_not_suspected_patients
     self.find_patients_with_last_observation([509], :value_coded, [508])
   end

   # Patients who were suspected to have TB on their last ART Visit
   def tb_suspected_patients
     self.find_patients_with_last_observation([509], :value_coded, [479])
   end

   # Patients who were confirmed to have TB on their last ART Visit but are not
   # on TB treatment
   def tb_confirmed_not_on_treatment_patients
     self.find_patients_with_last_observation([509], :value_coded, [477])
   end

   # Patients who were confirmed to have TB on their last ART Visit and are on
   # TB treatment
   def tb_confirmed_on_treatment_patients
     self.find_patients_with_last_observation([509], :value_coded, [478])
   end

   # Patients whose TB status was not known on their last ART visit
   def tb_status_unknown_patients
     self.patients_with_outcomes(['On ART']) -
       self.find_patients_with_last_observation([509],
                                                :value_coded,
                                                [508,479,477,478])
   end

  # Calculate values for Survival Analysis from previous year to the first
  # corresponding quarter
  def survival_analysis(survival_start_date=@start_date,
                        survival_end_date=@end_date,
                        outcome_end_date=@end_date, min_age=nil, max_age=nil)
    # Make sure these are always dates
    survival_start_date = start_date.to_date
    survival_end_date = end_date.to_date
    outcome_end_date = outcome_end_date.to_date

    date_ranges = Array.new
    first_registration_date = PatientRegistrationDate.find(:first,
      :order => 'registration_date').registration_date

    while (survival_start_date -= 1.year) >= first_registration_date
      survival_end_date   -= 1.year
      date_ranges << {:start_date => survival_start_date,
                      :end_date   => survival_end_date
      }
    end

    survival_analysis_outcomes = Array.new

    date_ranges.each_with_index do |date_range, i|
      outcomes_hash = Hash.new(0)
      all_outcomes = self.outcomes(date_range[:start_date], date_range[:end_date], outcome_end_date, min_age, max_age)

      outcomes_hash["Title"] = "#{(i+1)*12} month survival: outcomes by end of #{outcome_end_date.strftime('%B %Y')}"
      outcomes_hash["Start Date"] = date_range[:start_date]
      outcomes_hash["End Date"] = date_range[:end_date]

      survival_cohort = Reports::CohortByRegistrationDate.new(date_range[:start_date], date_range[:end_date])
      if max_age.nil?
        outcomes_hash["Total"] = survival_cohort.patients_started_on_arv_therapy.length rescue all_outcomes.values.sum
      else
        outcomes_hash["Total"] = all_outcomes.values.sum
      end
      outcomes_hash["Unknown"] = outcomes_hash["Total"] - all_outcomes.values.sum
      outcomes_hash["outcomes"] = all_outcomes

      # if there are no patients registered in that quarter, we must have
      # passed the real date when the clinic opened
      break if outcomes_hash["Total"] == 0
      
      survival_analysis_outcomes << outcomes_hash 
    end
    survival_analysis_outcomes
  end

  def children_survival_analysis
    self.survival_analysis(@start_date, @end_date, @end_date, 0, 14)
  end


  # Debugger

  # List patients with specificed occupation
  #
  # * Parameters
  #
  # +occupations+ - e.g. 'Farmer'
  #
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

  def patients_with_outcomes(outcomes, outcome_end_date=@end_date, min_age=nil, max_age=nil)
    concept_ids = []
    outcomes.each{|name|
      concept_ids << Concept.find_by_name(name).id rescue 0
    }
    conditions = ['registration_date >= ? AND registration_date <= ? AND outcome.outcome_concept_id IN (?) ',
                       @start_date, @end_date, concept_ids]
    conditions = ["registration_date >= ? AND registration_date <= ? AND outcome.outcome_concept_id IN (?) AND age_at_initiation >= ? AND age_at_initiation <= ?",
                                                 @start_date, @end_date, concept_ids, min_age, max_age] if min_age and max_age

    # outcome join specific for cohort debugger
    outcome_join = "INNER JOIN ( \
           SELECT * FROM ( \
             SELECT * \
             FROM patient_historical_outcomes \
             INNER JOIN ( \
               SELECT concept_id, 0 AS sort_weight FROM concept WHERE concept_id = 322 \
               UNION SELECT concept_id, 1 AS sort_weight FROM concept WHERE concept_id = 374 \
               UNION SELECT concept_id, 2 AS sort_weight FROM concept WHERE concept_id = 383 \
               UNION SELECT concept_id, 3 AS sort_weight FROM concept WHERE concept_id = 325 \
               UNION SELECT concept_id, 4 AS sort_weight FROM concept WHERE concept_id = 386 \
               UNION SELECT concept_id, 5 AS sort_weight FROM concept WHERE concept_id = 373 \
               UNION SELECT concept_id, 6 AS sort_weight FROM concept WHERE concept_id = 324 \
             ) AS ordered_outcomes ON ordered_outcomes.concept_id = patient_historical_outcomes.outcome_concept_id \
             WHERE outcome_date >= '#{@start_date}' AND outcome_date <= '#{outcome_end_date}' \
             ORDER BY DATE(outcome_date) DESC, sort_weight \
           ) as t GROUP BY patient_id \
        ) as outcome ON outcome.patient_id = patient_registration_dates.patient_id
        #{@@foreign_patients_join}"
    patients = PatientRegistrationDate.find(:all,
      :joins => "INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id
                 #{outcome_join} #{@@age_at_initiation_join}",
      :conditions => conditions,
      :group => 'patient.patient_id', :order => 'patient_id'
    )

    # include transfer outs by foreign arv number
    if concept_ids.include?(325)
      patients += self.patients_with_foreign_arv_number
    end

    patients
  end

  def patients_with_unknown_outcome(outcome_end_date=@end_date, min_age=nil, max_age=nil)
    if min_age and max_age
      self.patients_started_on_arv_therapy(min_age, max_age).map(&:patient_id) - self.patients_with_outcomes(
                                               ['On ART', 'Died', 'ART Stop', 'Defaulter'],
                                               outcome_end_date, min_age, max_age).map(&:patient_id) -
                                               self.transferred_out_patients(outcome_end_date, min_age, max_age).map(&:patient_id)
    else
      self.patients_started_on_arv_therapy.map(&:patient_id) - self.patients_with_outcomes(
                                               ['On ART', 'Died', 'ART Stop', 'Defaulter'],
                                               outcome_end_date).map(&:patient_id) -
                                               self.transferred_out_patients(outcome_end_date).map(&:patient_id)
    end
  end

  def patients_with_inconsistent_outcomes
    PatientHistoricalOutcome.find(:all,
                                  :conditions => ['outcome_concept_id = ? AND outcome_date <
                                    (SELECT MAX(outcome_date) FROM patient_historical_outcomes t1
                                     WHERE patient_historical_outcomes.patient_id = t1.patient_id AND
                                     outcome_concept_id != 322)', 322])
  end

  # Patients who currently have a foreign ARV number
  def patients_with_foreign_arv_number
    PatientRegistrationDate.find(
      :all,
      :joins => "INNER JOIN patient_identifier pi ON
                 pi.patient_id = patient_registration_dates.patient_id",
      :conditions => ["identifier_type=? AND LEFT(identifier,?) != ? AND
                       voided = 0",
                      18, @@arv_code.length, @@arv_code])
  end

  # Numbers of outcomes for foreign patients
  def outcomes_for_foreign_patients(outcome_join, conditions)
    outcome_hash = {}
    conditions[0] += ' AND identifier_type=? AND LEFT(identifier,?) != ? AND
                       patient_identifier.voided = 0'
    [18, @@arv_code.length, @@arv_code].each do |i|
      conditions << i
    end
    
    PatientRegistrationDate.find(
      :all,
      :joins => "INNER JOIN patient_identifier ON
        patient_identifier.patient_id = patient_registration_dates.patient_id
        #{outcome_join} #{@@age_at_initiation_join}
        INNER JOIN patient ON patient.patient_id =
                              patient_start_dates.patient_id",
      :conditions => conditions,
      :group  => 'outcome_concept_id',
      :select => 'outcome_concept_id, count(*) as count').map do |r|
        outcome_hash[r.outcome_concept_id.to_i] = r.count.to_i
      end
      outcome_hash
  end



  def children_with_outcomes(outcomes, outcome_end_date=@end_date, min_age=0, max_age=14)
    patients_with_outcomes(outcomes, outcome_end_date, min_age, max_age)
  end

  def children_defaulters(outcome_end_date=@end_date, min_age=0, max_age=14)
    patients_with_outcomes(['Defaulter'], outcome_end_date, min_age, max_age)
  end

  def patients_on_regimen(regimens)
    regimens = [regimens] if regimens.class == String
    concept_ids = []
    regimens.each do |name|
      name = 'ARV Non standard regimen' if name == 'Other'
      concept_ids << Concept.find_by_name(name).id rescue 0
    end
    on_art_concept_id = Concept.find_by_name("On ART").id

    extra_joins = "LEFT JOIN ( \
          SELECT * FROM ( \
            SELECT patient_historical_regimens.regimen_concept_id,\
            patient_historical_regimens.patient_id AS pid ,\
            patient_historical_regimens.category ,\
            FROM patient_historical_regimens \
            WHERE dispensed_date >= '#{@start_date}' AND dispensed_date <= '#{@end_date}' \
            ORDER BY dispensed_date DESC \
          ) as ordered_regimens \
          GROUP BY ordered_regimens.pid \
       ) as last_regimen ON last_regimen.pid = patient_registration_dates.patient_id"

    regimen_conditions = ["registration_date >= ? AND registration_date <= ? AND
      outcome_concept_id = ? AND regimen_concept_id IN (?)",
      @start_date, @end_date, on_art_concept_id, concept_ids]

    # This find is difficult because you need to join in the outcomes and
    # regimens, however you want to get the most recent outcome or regimen for
    # the period, meaning you have to group and sort and filter all within the
    # join. We use a left join for regimens so that unknown regimens show as
    # NULL.
    Patient.find(:all,
      :joins =>
        "INNER JOIN patient_registration_dates ON
          patient_registration_dates.patient_id = patient.patient_id
         
        #{extra_joins}
        #{@outcome_join} #{@@age_at_initiation_join}",
      :conditions => regimen_conditions,
      :group => "patient.patient_id")
  end

  def find_patients_with_last_observation(concepts, field = :value_coded, values = nil)
    values ||= [
      Concept.find_by_name("Yes").concept_id, 
      Concept.find_by_name("Yes drug induced").concept_id, 
      Concept.find_by_name("Yes not drug induced").concept_id, 
      Concept.find_by_name("Yes unknown cause").concept_id]
    PatientRegistrationDate.find(:all,
      :joins => 
        "INNER JOIN patient ON patient.patient_id =
                    patient_registration_dates.patient_id
         INNER JOIN ( \
          SELECT * FROM ( \
            SELECT * \
            FROM obs \
            INNER JOIN ( \
              SELECT * FROM ( \
                SELECT encounter.encounter_id AS eid, encounter.patient_id AS pid \
                FROM encounter \
                INNER JOIN (SELECT obs.encounter_id FROM obs
                  WHERE obs.voided = 0 GROUP BY encounter_id
                  ) AS obs1 ON obs1.encounter_id = encounter.encounter_id 
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
        
        #{@outcome_join} #{@@age_at_initiation_join}",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND outcome_concept_id = ?", @start_date, @end_date, 324])
  end

  def find_patients_with_staging_observation(concepts, field = 'value_coded', values = nil)
    values ||= [
      Concept.find_by_name("Yes").concept_id,
      Concept.find_by_name("Yes drug induced").concept_id,
      Concept.find_by_name("Yes not drug induced").concept_id,
      Concept.find_by_name("Yes unknown cause").concept_id]

    pre_start_staging = "SELECT encounter_id FROM encounter
           INNER JOIN obs USING(encounter_id)
           WHERE encounter_type = 5 AND obs.voided = 0 AND encounter.patient_id = patient.patient_id AND
                 encounter.encounter_datetime <= CONCAT(DATE(patient_start_dates.start_date), ' 23:59:59')
           ORDER BY encounter.encounter_datetime DESC
           LIMIT 1"
    post_start_staging = "SELECT encounter_id FROM encounter
           INNER JOIN obs USING(encounter_id)
           WHERE encounter_type = 5 AND obs.voided = 0 AND encounter.patient_id = patient.patient_id
           ORDER BY encounter.encounter_datetime DESC
           LIMIT 1"

    PatientRegistrationDate.find(:all,
      :select => "patient.patient_id,obs.encounter_id,
          (#{pre_start_staging}) AS enc_id1,
          (#{post_start_staging}) AS enc_id2
      ",

      :joins =>
        "INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id
         INNER JOIN obs ON obs.patient_id = patient.patient_id AND obs.concept_id
         #{@@age_at_initiation_join}
        ",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND
                       obs.concept_id IN (#{concepts.join(',')}) AND 
                       value_coded IN (#{values.join(',')}) AND
                       obs.encounter_id = (IFNULL((#{pre_start_staging}),(#{post_start_staging})))
                      ",
        @start_date, @end_date],
      :group => 'patient.patient_id HAVING obs.encounter_id = IFNULL(enc_id1,enc_id2)')
  end


  def cached_cohort_values
    start_date = @start_date.to_date
    end_date = @end_date.to_date
    report_values = CohortReportFieldValue.find(:all, :conditions => ['start_date = ? AND end_date = ?', 
                                                 start_date, end_date])
    value_hash = {}
    report_values.each do |report_value|
      value_hash[report_value.short_name] = report_value.value
    end

    value_hash
  end

  def report_values
    cohort_report = self #Reports::CohortByRegistrationDate.new(@quarter_start, @quarter_end)

    cohort_values ={} # self.cached_cohort_values 
    #return cohort_values unless cohort_values.blank?

    PatientStartDate.find(:first)
    PatientRegistrationDate.find(:first)
    PatientAdherenceDate.find(:first)
    PatientAdherenceRate.find(:first)
    PatientPrescriptionTotal.find(:first)
    PatientWholeTabletsRemainingAndBrought.find(:first)
    PatientHistoricalOutcome.find(:first)
    PatientHistoricalRegimen.find(:first)

#    cohort_values = Hash.new(0) #Patient.empty_cohort_data_hash
    cohort_values = Patient.empty_cohort_data_hash
    cohort_values['messages'] = []

    cohort_values['all_patients'] = cohort_report.patients_started_on_arv_therapy.length
    cohort_values['male_patients'] = cohort_report.men_started_on_arv_therapy.length
    cohort_values['female_patients'] = cohort_report.women_started_on_arv_therapy.length

    cohort_values['adult_patients'] = cohort_report.adults_started_on_arv_therapy.length
    cohort_values['child_patients'] = cohort_report.children_started_on_arv_therapy.length
    cohort_values['infant_patients'] = cohort_report.infants_started_on_arv_therapy.length
    cohort_values['transfer_in_patients'] = cohort_report.transfer_ins_started_on_arv_therapy.length
    cohort_values['new_patients'] = cohort_values['all_patients'] - cohort_values['transfer_in_patients']

=begin    
    cohort_values['occupations'] = cohort_report.occupations
    total_reported_occupations =  cohort_values['occupations']['housewife'] + 
      cohort_values['occupations']['farmer'] + cohort_values['occupations']['soldier/police'] + 
      cohort_values['occupations']['teacher'] + cohort_values['occupations']['business'] + 
      cohort_values['occupations']['healthcare worker'] + cohort_values['occupations']['student']

    cohort_values['occupations']['other'] = cohort_values['all_patients'] - 
                                             total_reported_occupations
=end                                             
    # Reasons  for Starting
    start_reasons = cohort_report.start_reasons
    cohort_values['start_reasons']  = start_reasons
    cohort_values['who_stage_1_or_2_cd4'] = start_reasons[0]["CD4 Count < 250"] +
                                            start_reasons[0]["CD4 Count < 350"] +
                                            start_reasons[0]["CD4 Count < 750"] +
                                            start_reasons[0]['CD4 percentage < 25'] || 0
    cohort_values['who_stage_2_lymphocyte'] = start_reasons[0]["Lymphocyte count below threshold with WHO stage 2"]
    cohort_values['infants_PCR'] = start_reasons[0]["PCR Test"]
    cohort_values['infants_presumed_severe_HIV'] = start_reasons[0]["Presumed HIV Disease"]
    cohort_values['child_hiv_positive'] = start_reasons[0]["Child HIV positive"]
    cohort_values['breastfeeding_mothers'] = start_reasons[0]["Breastfeeding"]
    cohort_values['started_cause_pregnant'] = start_reasons[0]["Pregnant"]
    cohort_values['who_stage_3'] = start_reasons[0]["WHO stage 3"] || start_reasons[0]["WHO Stage 3"] || start_reasons[0][" Stage 3"] || 0
    cohort_values['who_stage_4'] = start_reasons[0]["WHO stage 4"] || start_reasons[0]["WHO Stage 4"] || start_reasons[0][" Stage 4"] || 0
    cohort_values['start_reason_other'] = start_reasons[0]["Other"] || 0

#    cohort_values["start_cause_TB"] = self.find_patients_with_staging_observation([283,295,296]).length
#    cohort_values["start_cause_TB"] = start_reasons[0]['start_cause_EPTB'] +
#                                       start_reasons[0]['start_cause_PTB'] +
#                                       start_reasons[0]['start_cause_APTB']
    cohort_values["start_cause_current_tb"] = self.find_patients_with_staging_observation(
      [Concept.find_by_name('Pulmonary tuberculosis (current)').id]).length
    cohort_values["start_cause_tb_within_two_years"] = self.find_patients_with_staging_observation(
      [Concept.find_by_name('Pulmonary tuberculosis within the last 2 years').id,
       Concept.find_by_name('Extrapulmonary tuberculosis').id]).length
    cohort_values["start_cause_no_tb"] = cohort_values['all_patients'] -
                                         cohort_values["start_cause_current_tb"] -
                                         cohort_values["start_cause_tb_within_two_years"]

    cohort_values["start_cause_KS"] = start_reasons[0]['start_cause_KS']
    cohort_values["pmtct_pregnant_women_on_art"] = cohort_report.pregnant_women.length
    cohort_values['non_pregnant_women'] = cohort_values["female_patients"] - cohort_values["pmtct_pregnant_women_on_art"]

    regimens = cohort_report.regimens
    #cohort_values['regimen_types'] = cohort_report.regimen_types
    #cohort_values['regimen_types'] = Hash.new(0)
    
    regimen_breakdown = Hash.new(0)
    regimens.map do |regimen_category,number|
      category = regimen_category
      category = "Other Regimen" if category.blank?
      cohort_values[category] = number 
    end
=begin
    cohort_values['ARV First line regimen']   = regimen_breakdown['Stavudine Lamivudine Nevirapine Regimen']
    cohort_values['1st_line_alternative_ZLN'] = regimen_breakdown['Zidovudine Lamivudine Nevirapine Regimen']
    cohort_values['1st_line_alternative_SLE'] = regimen_breakdown['Stavudine Lamivudine Efavirenz Regimen'] 
    cohort_values['1st_line_alternative_ZLE'] = regimen_breakdown['Zidovudine Lamivudine Efavirenz Regimen']
    cohort_values['ARV First line regimen alternatives'] = cohort_values['1st_line_alternative_ZLN'] +
                                                            cohort_values['1st_line_alternative_SLE'] +
                                                            cohort_values['1st_line_alternative_ZLE']
    
    cohort_values['2nd_line_alternative_ZLTLR'] = regimen_breakdown['Zidovudine Lamivudine Tenofovir Lopinavir/Ritonavir Regimen']
    cohort_values['2nd_line_alternative_DALR']  = regimen_breakdown['Didanosine Abacavir Lopinavir/Ritonavir Regimen'] 
    cohort_values['ARV Second line regimen']    = cohort_values['2nd_line_alternative_ZLTLR'] + 
                                                   cohort_values['2nd_line_alternative_DALR']
    
    cohort_values['other_regimen'] = regimen_breakdown['Other Regimen'] +
                                     regimen_breakdown['Unknown Regimen'] +
                                     regimen_breakdown['ARV Non standard regimen']
=end

    outcomes = cohort_report.outcomes
    cohort_values['alive_on_ART_patients']    = outcomes[Concept.find_by_name('On ART').id]
    cohort_values['dead_patients']            = outcomes[Concept.find_by_name('Died').id]
    cohort_values['defaulters']               = outcomes[Concept.find_by_name('Defaulter').id]
    cohort_values['art_stopped_patients']     = outcomes[Concept.find_by_name('ART Stop').id]
    cohort_values['transferred_out_patients'] = outcomes[Concept.find_by_name('Transfer out').id] + 
                                                 outcomes[Concept.find_by_name('Transfer Out(With Transfer Note)').id] +
                                                 outcomes[Concept.find_by_name('Transfer Out(Without Transfer Note)').id]


    side_effects = cohort_report.side_effects

    cohort_values['peripheral_neuropathy_patients'] = side_effects[Concept.find_by_name('Peripheral neuropathy').id] + 
                                                       side_effects[Concept.find_by_name('Leg pain / numbness').id]
    cohort_values['hepatitis_patients'] = side_effects[Concept.find_by_name('Hepatitis').id] + 
                                           side_effects[Concept.find_by_name('Jaundice').id]
    cohort_values['skin_rash_patients'] = side_effects[Concept.find_by_name('Skin rash').id]
    cohort_values['side_effect_patients'] = side_effects["side_effects_patients"]

    cohort_values['patients_with_few_dosses_missed'] = cohort_report.patients_with_few_dosses_missed.length
    cohort_values['patients_with_more_dosses_missed'] = cohort_report.patients_with_more_dosses_missed.length
#    cohort_values['adults_on_1st_line_with_pill_count'] = cohort_report.adults_on_first_line_with_pill_count.length
#    cohort_values['patients_with_pill_count_less_than_eight'] = cohort_report.adults_on_first_line_with_pill_count_with_eight_or_less.length
    cohort_values['adherent_patients'] = cohort_report.adherent_patients.length

    death_dates = cohort_report.death_dates
    cohort_values['died_1st_month'] = death_dates[0]
    cohort_values['died_2nd_month'] = death_dates[1]
    cohort_values['died_3rd_month'] = death_dates[2]
    cohort_values['died_after_3rd_month'] = death_dates[3]

    cohort_values['tb_not_suspected_patients'] = cohort_report.tb_not_suspected_patients.length
    cohort_values['tb_suspected_patients']     = cohort_report.tb_suspected_patients.length
    cohort_values['tb_confirmed_not_on_treatment_patients'] = cohort_report.tb_confirmed_not_on_treatment_patients.length
    cohort_values['tb_confirmed_on_treatment_patients'] = cohort_report.tb_confirmed_on_treatment_patients.length

    cohort_values['re_initiated_patients'] = cohort_report.re_initiated_patients.length

    cohort_values    
  end

  def names_to_short_names
    fields = CohortReportField.find(:all)
    names_to_codes = {}
    fields.each do |field|
      names_to_codes[field.name] = field.short_name
    end

    names_to_codes
  end

  def names_to_sort_weights
    fields = CohortReportField.find(:all)
    sort_weights = {}
    fields.each do |field|
      sort_weights[field.name] = field.sort_weight
    end

    sort_weights
  end

  def quarterly?
    start_date = @start_date.to_date
    end_date = @end_date.to_date
    quarter_end_days = {'01-01' => '03-31', '04-01' => '06-30', 
                        '07-01' => '09-30', '10-01' => '12-31'}

    puts start_date.strftime('%m-%d')
    return false if quarter_end_days[start_date.strftime('%m-%d')].nil?

    quarter_end_days[start_date.strftime('%m-%d')] == end_date.strftime('%m-%d')
  end

  def save(values=nil)
    start_date = @start_date.to_date
    end_date = @end_date.to_date
    values = self.report_values unless values
    values.each_pair do |key, value|
      next if value.class != Fixnum
      report_field = CohortReportFieldValue.find(:first, :conditions => ['start_date = ? AND end_date = ? AND short_name = ?',
                                                                         start_date, end_date, key])

      report_field = CohortReportFieldValue.new unless report_field
      report_field.start_date = @start_date
      report_field.end_date = @end_date
      report_field.short_name = key
      report_field.value = value
      report_field.save
    end
  end

  def clear_cache
    start_date = @start_date.to_date
    end_date = @end_date.to_date
    CohortReportFieldValue.delete_all(['start_date = ? AND end_date = ?', 
                                                       start_date, end_date])
  end

  def short_name_to_method #(short_name)
    {
     'patients_with_few_dosses_missed' => 'patients_with_few_dosses_missed',
     'adults_on_1st_line_with_pill_count' => 'adults_on_first_line_with_pill_count',
     'alive_on_ART_patients' => 'patients_with_outcomes,On ART',
     'art_stopped_patients' => 'patients_with_outcomes,ART Stop',
     'ARV First line regimen' => 'patients_on_regimen,Stavudine Lamivudine Nevirapine Regimen',
#     'ARV First line regimen alternatives' => 'ARV First line regimen alternatives',
#     'ARV Second line regimen' => 'ARV Second line regimen',
     'dead_patients'  => 'patients_with_outcomes,Died',
     'defaulters'     => 'patients_with_outcomes,Defaulter',
     'died_1st_month' => 'find_all_dead_patients,died_1st_month',
     'died_2nd_month' => 'find_all_dead_patients,died_2nd_month',
     'died_3rd_month' => 'find_all_dead_patients,died_3rd_month',
     'died_after_3rd_month' => 'find_all_dead_patients,died_after_3rd_month',
     'unknown_outcome' => 'patients_with_unknown_outcome',
=begin 
     '1st_line_alternative_SLE' => 'patients_on_regimen,Stavudine Lamivudine Efavirenz Regimen',
     '1st_line_alternative_ZLE' => 'patients_on_regimen,Zidovudine Lamivudine Efavirenz Regimen',
     '1st_line_alternative_ZLN' => 'patients_on_regimen,Zidovudine Lamivudine Nevirapine Regimen',
     '2nd_line_alternative_DALR' => 'patients_on_regimen,Didanosine Abacavir Lopinavir/Ritonavir Regimen',
     '2nd_line_alternative_ZLTLR' => 'patients_on_regimen,Zidovudine Lamivudine Tenofovir Lopinavir/Ritonavir Regimen',
=end
     'other_regimen' => 'regimen_type,other_regimen',
     'A1' => 'regimen_type,A1','A2' => 'regimen_type,A2','A3' => 'regimen_type,A3',
     'A4' => 'regimen_type,A4','A5' => 'regimen_type,A5','A6' => 'regimen_type,A6',
     'A7' => 'regimen_type,A7','A8' => 'regimen_type,A8','A9' => 'regimen_type,A9',
     'P1' => 'regimen_type,P1','P2' => 'regimen_type,P2','P3' => 'regimen_type,P3',
     'P4' => 'regimen_type,P4','P5' => 'regimen_type,P5','P6' => 'regimen_type,P6',
     'P7' => 'regimen_type,P7','P8' => 'regimen_type,P8','P9' => 'regimen_type,P9',

     'patients_with_pill_count_less_than_eight' => 'adults_on_first_line_with_pill_count_with_eight_or_less',
     'adherent_patients' => 'adherent_patients',
     'over_adherent_patients' => 'over_adherent_patients',
     
     'transferred_out_patients' => 'transferred_out_patients',
     'transfer_in_patients' => 'transfer_ins_started_on_arv_therapy',
     'new_patients' => 'new_patients',
     'male_patients' => 'men_started_on_arv_therapy',
     'non_pregnant_women' => 'non_pregnant_women',
     #'pmtct_pregnant_women_on_art' => 'patients_with_start_reason,pmtct_pregnant_women_on_art',
     'pmtct_pregnant_women_on_art' => 'pregnant_women',
     'adult_patients' => 'adults_started_on_arv_therapy',
     'child_patients' => 'children_started_on_arv_therapy',
     'infant_patients' => 'infants_started_on_arv_therapy',
     'infants_presumed_severe_HIV' => 'patients_with_start_reason,Presumed HIV Disease',
     'child_hiv_positive' => 'patients_with_start_reason,Child HIV Positive',
     'breastfeeding_mothers' => 'patients_with_start_reason,Breastfeeding',
     'started_cause_pregnant' => 'patients_with_start_reason,Pregnant',
     'infants_PCR' => 'patients_with_start_reason,PCR Test',
     'who_stage_1_or_2_cd4' => 'patients_with_start_reason,who_stage_1_or_2_cd4',
     'who_stage_2_lymphocyte' => 'patients_with_start_reason,Lymphocyte count below threshold with WHO stage 2',
     'who_stage_3' => 'patients_with_start_reason,WHO stage 3',
     'who_stage_4' => 'patients_with_start_reason,WHO stage 4',

     'side_effect_patients' => 'side_effect_patients',
     'start_reason_other' => 'patients_with_start_reason,Other',
     'start_cause_no_tb' => 'patients_with_start_cause,start_cause_no_tb',
     'start_cause_tb_within_two_years' => 'patients_with_start_cause,start_cause_tb_within_two_years',
     'start_cause_current_tb' => 'patients_with_start_cause,start_cause_current_tb',
     'start_cause_TB' => 'patients_with_start_cause,start_cause_TB',
     'start_cause_KS' => 'patients_with_start_cause,start_cause_KS',
     'all_patients' => 'patients_started_on_arv_therapy',
    
     'arv_number_range' => 'arv_number_range',
     'not_in_arv_number_range' => 'not_in_arv_number_range',
     'dispensations_without_prescriptions' => 'dispensations_without_prescriptions',
     'prescriptions_without_dispensations' => 'prescriptions_without_dispensations'
    }
  end

  def arv_number_range
    min_arv_number = PatientRegistrationDate.find(:all,
                                 :joins => 'INNER JOIN patient_identifier ON 
      patient_identifier.patient_id = patient_registration_dates.patient_id AND 
      patient_identifier.identifier_type = 18 AND patient_identifier.voided = 0',
                                 :conditions => ["registration_date >= ? AND registration_date <= ?", @start_date, @end_date],
                                 :order => 'CAST(SUBSTR(identifier,4) AS UNSIGNED)', :limit => 1) 
    max_arv_number = PatientRegistrationDate.find(:all,
                                 :joins => 'INNER JOIN patient_identifier ON 
      patient_identifier.patient_id = patient_registration_dates.patient_id AND 
      patient_identifier.identifier_type = 18 AND patient_identifier.voided = 0',
                                 :conditions => ["registration_date >= ? AND registration_date <= ?", @start_date, @end_date],
                                 :order => 'CAST(SUBSTR(identifier,4) AS UNSIGNED) DESC', :limit => 1) 
    [min_arv_number.first, max_arv_number.first]
  end

  def not_in_arv_number_range(min, max)
    PatientRegistrationDate.find(:all,
      :joins => 'INNER JOIN patient_identifier ON
      patient_identifier.patient_id = patient_registration_dates.patient_id AND
      patient_identifier.identifier_type = 18 AND patient_identifier.voided = 0',
      :conditions => ["registration_date >= ? AND registration_date <= ? AND
                     CAST(SUBSTR(identifier,4) AS UNSIGNED) NOT BETWEEN ? AND ?",
                     @start_date, @end_date, min.to_i, max.to_i],
      :order => 'CAST(SUBSTR(identifier,4) AS UNSIGNED)')
  end
 
  def in_arv_number_range(min, max)
    PatientRegistrationDate.find(:all,
      :joins => 'INNER JOIN patient ON patient.patient_id =
                            patient_registration_dates.patient_id
        INNER JOIN patient_identifier ON
          patient_identifier.patient_id = patient_registration_dates.patient_id AND
          patient_identifier.identifier_type = 18 AND patient_identifier.voided = 0',
      :conditions => ["(registration_date < ? OR registration_date > ?) AND CAST(SUBSTR(identifier,4) AS UNSIGNED) BETWEEN ? AND ?",
                     @start_date, @end_date, min.to_i, max.to_i],
      :order => 'CAST(SUBSTR(identifier,4) AS UNSIGNED)')
  end

  def prescriptions
    prescription_encounters = Encounter.find(:all,
                                             :joins => "INNER JOIN obs ON obs.encounter_id = encounter.encounter_id AND obs.voided = 0 AND \
                                                       obs.concept_id =  #{Concept.find_by_name('Prescribed dose').id}",
                            :conditions => ["encounter_datetime >= ? AND encounter_datetime <= ? AND encounter_type = ?", 
                              @start_date, @end_date, EncounterType.find_by_name("ART visit").id])
    prescriptions_hash = Hash.new()
    cpt_id = Drug.find_by_name('Cotrimoxazole 480').id

    prescription_encounters.each{|e|
        prescriptions_hash[e.patient_id] = [] if not prescriptions_hash[e.patient_id]
        temp_hash = {}
        temp_hash[e.encounter_datetime.strftime("%Y-%m-%d")] = e.observations.collect{|obs| 
          next if obs.concept.name =~ /remaining/
            obs.value_drug if (obs.value_drug && obs.value_drug != cpt_id) rescue []}.uniq.compact.sort
        prescriptions_hash[e.patient_id] <<  temp_hash if temp_hash[e.encounter_datetime.strftime("%Y-%m-%d")] != []
        prescriptions_hash[e.patient_id] = prescriptions_hash[e.patient_id].map {|h| h.to_a[0]}.uniq.map {|k,v| {k => v}}
    }
    return prescriptions_hash

  end
  
  def dispensations

    dispensation_encounters = Encounter.find(:all,
                                            :joins => "INNER JOIN orders ON orders.encounter_id = encounter.encounter_id \
                                                   AND orders.voided = 0",
                                            :conditions => ["encounter_datetime >= ? AND encounter_datetime <= ? AND encounter_type = ?", 
                                                @start_date, @end_date, EncounterType.find_by_name("Give drugs").id])
    dispensations_hash = Hash.new()

    dispensation_encounters.each{|e|
        dispensations_hash[e.patient_id] = [] if not dispensations_hash[e.patient_id]
        temp_hash = {}
        temp_hash[e.encounter_datetime.strftime("%Y-%m-%d")] = e.drug_orders.collect{|order| order.drug.id unless order.drug.name =="Cotrimoxazole 480"}.uniq.compact.sort
        dispensations_hash[e.patient_id] <<  temp_hash if temp_hash[e.encounter_datetime.strftime("%Y-%m-%d")] != []
        dispensations_hash[e.patient_id] = dispensations_hash[e.patient_id].map {|h| h.to_a[0]}.uniq.map {|k,v| {k => v}}
    }
    return dispensations_hash
  end

  def dispensations_without_prescriptions
    dispensations_hash = self.dispensations
    prescriptions_hash = self.prescriptions
    dispensations_without_prescriptions = {}
    dispensations_hash.each{|k,v|  
      v.each{|ary| 
        encounter_date = Date.today.strftime('%Y-%m-%d')
          dispensed_drugs = []
          ary.each{|enc_date,drug_ids| 
            encounter_date = enc_date
            dispensed_drugs = drug_ids
          }
          prescribed_drugs = []
          difference = []
          temp_hash = {}

        if prescriptions_hash[k] and !prescriptions_hash[k].include?(ary)
            prescriptions_hash[k].each{|element|
            element.each{|key,value|
              prescribed_drugs = value if key == encounter_date
            }
          }
        elsif prescriptions_hash[k] and prescriptions_hash[k].include?(ary)
          next
        elsif !prescriptions_hash[k]
           prescribed_drugs = []
        end

          difference = dispensed_drugs - prescribed_drugs
          next if difference == []
          temp_hash[encounter_date] = difference
          dispensations_without_prescriptions[k] = [] if not dispensations_without_prescriptions[k]
          dispensations_without_prescriptions[k] << temp_hash
      }
    }
    return dispensations_without_prescriptions
  end

  def missing_dispensations
    patients = Patient.find_by_sql ["
      SELECT patient_id, DATE(p.prescription_datetime) AS visit_date, p.drug_id FROM patient_prescriptions p
        WHERE prescription_datetime >= ? AND prescription_datetime <= ? AND
        NOT EXISTS (
          SELECT * FROM orders
            INNER JOIN encounter USING(encounter_id)
            INNER JOIN drug_order USING(order_id)
          WHERE patient_id = p.patient_id AND orders.voided = 0 AND
                DATE(encounter_datetime) = DATE(p.prescription_datetime) AND
                p.drug_id = drug_order.drug_inventory_id
        )
        ORDER BY p.prescription_datetime DESC ", @start_date, @end_date]
    patient_data = {}
    patients.each do |patient|
      patient_data[patient.patient_id] = [] unless patient_data[patient.patient_id]
      patient_data[patient.id] << {patient.visit_date => patient.drug_id}
    end

    patient_data
  end

  def missing_prescriptions
    patients = Patient.find_by_sql ["
      SELECT encounter.patient_id, DATE(encounter_datetime) AS visit_date,
             drug_order.drug_inventory_id AS drug_id
        FROM orders
        INNER JOIN encounter USING(encounter_id)
        INNER JOIN drug_order USING(order_id)
        INNER JOIN drug ON drug.drug_id = drug_order.drug_inventory_id
        INNER JOIN concept_set ON concept_set.concept_id = drug.concept_id
        WHERE encounter_datetime >= ? AND
              encounter_datetime <= ? AND
              concept_set.concept_set = 460 AND
              orders.voided = 0 AND
          NOT EXISTS (
          SELECT patient_id, DATE(p.prescription_datetime) AS visit_date, p.drug_id
            FROM patient_prescriptions p
            WHERE encounter.patient_id = p.patient_id  AND
                DATE(encounter_datetime) = DATE(p.prescription_datetime) AND
                p.drug_id = drug_order.drug_inventory_id
          )
        ORDER BY encounter_datetime DESC", @start_date, @end_date]
    patient_data = {}
    patients.each do |patient|
      patient_data[patient.patient_id] = [] unless patient_data[patient.patient_id]
      patient_data[patient.id] << {patient.visit_date => patient.drug_id}
    end

    patient_data
  end

  def prescriptions_without_dispensations
    dispensations_hash = self.dispensations
    prescriptions_hash = self.prescriptions
    prescriptions_without_dispensations = {}
    prescriptions_hash.each{|k,v|  
      v.each{|ary| 
        encounter_date = Date.today.strftime('%Y-%m-%d')
        prescribed_drugs = []
        ary.each{|enc_date,drug_ids| 
            encounter_date = enc_date
            prescribed_drugs = drug_ids
        }
        dispensed_drugs = []
        difference = []
        temp_hash = {}

        if dispensations_hash[k] and !dispensations_hash[k].include?(ary)
            dispensations_hash[k].each{|element|
            element.each{|key,value|
              dispensed_drugs = value if key == encounter_date
            }
          }
        elsif dispensations_hash[k] and dispensations_hash[k].include?(ary)
          next
        elsif !dispensations_hash[k]
          dispensed_drugs = []
        end
          difference = prescribed_drugs - dispensed_drugs
          next if difference == []
          temp_hash[encounter_date] = difference
          prescriptions_without_dispensations[k] = [] if not prescriptions_without_dispensations[k]
          prescriptions_without_dispensations[k] << temp_hash 
      }
    }
    return prescriptions_without_dispensations
  end

  def patients_with_multiple_start_reasons
    patients = Patient.find(:all,
                           :joins => "INNER JOIN patient_registration_dates ON \
                                      patient_registration_dates.patient_id = patient.patient_id
                                      INNER JOIN encounter on encounter.patient_id = patient.patient_id \
                                      INNER JOIN obs on encounter.encounter_id = obs.encounter_id AND \
                                      encounter.encounter_type = #{EncounterType.find_by_name("HIV Staging").id}",
                           :conditions => ["registration_date >= ? AND registration_date <= ? AND obs.voided=0",@start_date, @end_date],
                           :group => 'patient.patient_id HAVING COUNT(encounter.encounter_id) > 1')
    patient_start_reasons = {}

    patients.each{|p|
      hiv_encounters = p.encounters.find_by_type_name("HIV Staging")
      patient_start_reasons[p.patient_id] = []
      hiv_encounters.each{|enc|
	#next if enc.

        next if enc.observations.first.voided == true rescue nil
#	created_date = {}
#	created_date[enc.date_created.strftime("%Y-%m-%d %H:%M:%S")] = enc.reason_for_starting_art(enc.date_created).name rescue 'None'
#	next if created_date[enc.date_created.strftime("%Y-%m-%d %H:%M:%S")] == 'None'
        start_reason = {}
        start_reason[enc.encounter_datetime.strftime("%Y-%m-%d")] = "#{enc.date_created.strftime("%Y-%m-%d %H:%M:%S")}--#{enc.reason_for_starting_art(enc.encounter_datetime).name}" rescue 'None'
        next if start_reason[enc.encounter_datetime.strftime("%Y-%m-%d")] == 'None'
        patient_start_reasons[p.patient_id] << start_reason
      }
    }
    patient_start_reasons.delete_if{|key, value| value.length < 2 }
    return patient_start_reasons

  end

  # Patients whose adherence rate is between 95%  and 105%
  def adherent_patients
    self.patients_with_adherence
  end

  def over_adherent_patients
    self.patients_with_adherence(106, 999999999)
  end

  def under_adherent_patients
    self.patients_with_adherence(0, 94)
  end

  # Patients whose adherence rate is between 95% and 105%
  def patients_with_adherence(min=95, max=105)
    PatientRegistrationDate.find(:all,
      :joins => "INNER JOIN patient on patient.patient_id =
                            patient_registration_dates.patient_id \
       #{@outcome_join} #{@@age_at_initiation_join}
       INNER JOIN (
          SELECT r.patient_id, r.visit_date, (
            SELECT visit_date FROM patient_adherence_rates t
            WHERE patient_id = r.patient_id AND visit_date <= '#{@end_date.to_date}'
            ORDER BY visit_date DESC
            LIMIT 1
          ) AS latest_date, r.adherence_rate
          FROM patient_adherence_rates r
          HAVING visit_date = latest_date AND adherence_rate BETWEEN #{min} AND #{max}
          ) AS adherent_patients ON patient_registration_dates.patient_id = adherent_patients.patient_id AND
          registration_date BETWEEN '#{@start_date}' AND '#{@end_date}'",
      :conditions => ['registration_date >= ? AND registration_date <= ? AND
                       outcome_concept_id = ?', @start_date, @end_date, 324],
      :group => 'patient_registration_dates.patient_id'
    )
  end

  ## Children Cohort Code, duct tape version -- TODO where should this code be?
  
  def children_transfer_ins_started_on_arv_therapy(min_age=0, max_age=14)
    PatientRegistrationDate.find(:all, :joins => "#{@@age_at_initiation_join} INNER JOIN patient ON patient.patient_id = patient_registration_dates.patient_id INNER JOIN obs ON obs.patient_id = patient.patient_id AND obs.voided = 0", 
                           :conditions => ["registration_date >= ? AND registration_date <= ? AND obs.concept_id = ? AND value_coded = ? AND age_at_initiation >= ? AND age_at_initiation < ?", 
                                           @start_date, @end_date, 
                                           Concept.find_by_name('Ever registered at ART clinic').id, 
                                           Concept.find_by_name('Yes').id,
                                           min_age, 
                                           max_age+1])
  end

  def new_children(min_age=0, max_age=14)
    self.children_started_on_arv_therapy(min_age, max_age) - self.children_transfer_ins_started_on_arv_therapy(min_age, max_age)
  end

  def children_regimens(min_age=0, max_age=14)
    regimen_hash = Hash.new(0)
    # This find is difficult because you need to join in the outcomes and 
    # regimens, however you want to get the most recent outcome or regimen for 
    # the period, meaning you have to group and sort and filter all within the 
    # join. We use a left join for regimens so that unknown regimens show as 
    # NULL. 
    PatientRegistrationDate.find(:all,
      :joins => 
        "LEFT JOIN ( \
            SELECT * FROM ( \
              SELECT patient_historical_regimens.regimen_concept_id, patient_historical_regimens.patient_id AS pid \
              FROM patient_historical_regimens \
              WHERE dispensed_date >= '#{@start_date}' AND dispensed_date <= '#{@end_date}' \
              ORDER BY dispensed_date DESC \
            ) as ordered_regimens \
            GROUP BY ordered_regimens.pid \
         ) as last_regimen ON last_regimen.pid = patient_registration_dates.patient_id \
        
        #{@outcome_join}
        #{@@age_at_initiation_join}",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND outcome_concept_id = ? AND age_at_initiation >= ? AND age_at_initiation < ?", @start_date, @end_date, 324, min_age, max_age+1],
      :group => "regimen_concept_id",
      :select => "regimen_concept_id, count(*) as count").map {|r| regimen_hash[r.regimen_concept_id.to_i] = r.count.to_i }
    regimen_hash
  end
   

  def children_outcomes(min_age=0, max_age=14)
    self.outcomes(@start_date, @end_date, @end_date, min_age, max_age)
  end

  # Get patients reinitiated on art count
=begin
  def patients_reinitiated_on_art_ever
    Observation.find(:all, :conditions => ["concept_id = ? AND value_coded IN (?) AND obs.voided = 0 \
                  AND obs_datetime <= ?", Concept.find_by_name("Ever received ART").concept_id,
                  Concept.find(:all, :conditions => ["name = 'Yes'"]).collect{|c| c.concept_id}, @end_date]).length rescue 0
  end
=end

  # Patients who started ART at another site but had stopped taking ART for at
  # least 2 months when they transferred to the current site
  #
  def re_initiated_patients

    PatientRegistrationDate.find(:all,
      :joins => "#{@@age_at_initiation_join}
        INNER JOIN obs ON obs.patient_id = patient_registration_dates.patient_id",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND
                       concept_id = ? AND value_coded = ? AND
                       concept_id = ? AND value_coded != ? AND
                       obs.voided = 0",
                       @start_date, @end_date, 
                       Concept.find_by_name('Ever registered at ART clinic').id,
                       Concept.find_by_name('Yes').id,
                       Concept.find_by_name('Taken ARVs in last 2 months').concept_id,
                       Concept.find_by_name('Yes').id])

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
        
        #{@outcome_join} #{@@age_at_initiation_join}",
      :conditions => ["registration_date >= ? AND registration_date <= ? AND outcome_concept_id = ?", @start_date, @end_date, 324])
  end
  
  # Checking for the number of patients that have value as their most recent
  # observation for the given set of concept ids
  def count_last_observations_for(concepts, field = :value_coded, values = nil)
    self.find_patients_with_last_observation(concepts, field, values).length
  end


  def count_staging_observations_for(concepts)
    self.find_patients_with_staging_observation(concepts).length
  end

  def load_start_reason_patient(reason, patient_id)
    @start_reason_patient_ids[reason] = [] unless @start_reason_patient_ids[reason]
    @start_reason_patient_ids[reason] << patient_id
  end

end
