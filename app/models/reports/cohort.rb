class Reports::Cohort
   
  attr_accessor :start_date, :end_date
 
  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date 
  end
   
  def patients_started_on_arv_therapy
    PatientStartDate.count(:conditions => ["start_date >= ? AND start_date <= ?", @start_date, @end_date])
  end

  def men_started_on_arv_therapy
    # removed :include because it uses DISTINCT when passed to count. We don't want DISTINCT
    PatientStartDate.count(:joins => "INNER JOIN patient ON patient.patient_id = patient_start_dates.patient_id",
                                  :conditions => ["start_date >= ? AND start_date <= ? AND patient.gender = 'Male'", @start_date, @end_date])
  end

  def women_started_on_arv_therapy
    # removed :include because it uses DISTINCT when passed to count. We don't want DISTINCT
    PatientStartDate.count(:joins => "INNER JOIN patient ON patient.patient_id = patient_start_dates.patient_id",
                                  :conditions => ["start_date >= ? AND start_date <= ? AND patient.gender = 'Female'", @start_date, @end_date])
  end

  def adults_started_on_arv_therapy
    PatientStartDate.count(:conditions => ["start_date >= ? AND start_date <= ? AND age_at_initiation >= ?", @start_date, @end_date, 15])
  end

  def children_started_on_arv_therapy
    PatientStartDate.count(:conditions => ["start_date >= ? AND start_date <= ? AND age_at_initiation <= ?", @start_date, @end_date, 14])
  end

  def occupations
    occupation = PatientIdentifierType.find_by_name("Occupation").patient_identifier_type_id
    occupation_hash = Hash.new(0)
    PatientStartDate.find(:all,
      :joins => 
        "INNER JOIN patient_identifier ON \
           patient_identifier.patient_id = patient_start_dates.patient_id AND \
           patient_identifier.voided = 0 AND \
           patient_identifier.identifier_type = #{occupation}",
      :conditions => ["start_date >= ? AND start_date <= ?", @start_date, @end_date],
      :group => "identifier",
      :order => "patient_identifier.date_created DESC",
      :select => "identifier, count(*) as count").map {|r| occupation_hash[r.identifier] = r.count.to_i }
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
   
  def outcomes
    outcome_hash = Hash.new(0)
    # This find is difficult because you need to join in the outcomes, however
    # you want to get the most recent outcome for the period, meaning you have
    # to group and sort and filter all within the join
    PatientStartDate.find(:all,
      :joins => 
        "INNER JOIN ( \
           SELECT * FROM ( \
             SELECT * \
             FROM patient_outcomes \
             WHERE outcome_date >= '#{@start_date.to_formatted_s}' AND outcome_date <= '#{@end_date.to_formatted_s}' \
             ORDER BY outcome_date DESC \
           ) as t GROUP BY patient_id \
        ) as outcome ON outcome.patient_id = patient_start_dates.patient_id",
      :conditions => ["start_date >= ? AND start_date <= ?", @start_date, @end_date],
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
    PatientStartDate.find(:all,
      :joins => 
        "INNER JOIN ( \
          SELECT * FROM (
            SELECT * \
            FROM patient_outcomes \
            WHERE outcome_date >= '#{@start_date.to_formatted_s}' AND outcome_date <= '#{@end_date.to_formatted_s}' AND outcome_concept_id = #{on_art_concept_id} \
            ORDER BY outcome_date DESC \
          ) as t GROUP BY patient_id \
          
          ) as outcome ON outcome.patient_id = patient_start_dates.patient_id
          LEFT JOIN ( \
            SELECT * FROM (
              SELECT * \
              FROM patient_regimens \
              WHERE dispensed_date >= '#{@start_date.to_formatted_s}' AND dispensed_date <= '#{@end_date.to_formatted_s}' \
              ORDER BY dispensed_date DESC \
            ) as t2 GROUP BY patient_id \
          LIMIT 1
        ) as regimen ON regimen.patient_id = patient_start_dates.patient_id",
      :conditions => ["start_date >= ? AND start_date <= ?", @start_date, @end_date],            
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
        "INNER JOIN patient_start_dates \
           ON start_date >= '#{@start_date.to_formatted_s}' AND start_date <= '#{@end_date.to_formatted_s}' AND \
              patient_start_dates.patient_id = patient_whole_tablets_remaining_and_brought.patient_id AND \
              age_at_initiation >= 15",
      :conditions => ["visit_date >= ? AND visit_date <= ?", @start_date, @end_date],      
      :group => "patient_whole_tablets_remaining_and_brought.patient_id").size
  end
  
  # With pill count in the last month of the quarter at 8 or less
  def adults_on_first_line_with_pill_count_with_eight_or_less
    ## TODO, not limiting to first line
    PatientWholeTabletsRemainingAndBrought.find(:all,                                              
      :joins => 
        "INNER JOIN patient_start_dates \
           ON start_date >= '#{@start_date.to_formatted_s}' AND start_date <= '#{@end_date.to_formatted_s}' AND \
              patient_start_dates.patient_id = patient_whole_tablets_remaining_and_brought.patient_id AND \
              age_at_initiation >= 15",
      :conditions => ["visit_date >= ? AND visit_date <= ? AND total_remaining < 8", @start_date, @end_date],      
      :group => "patient_whole_tablets_remaining_and_brought.patient_id").size
  end
  
  def death_dates
    first_month = PatientStartDate.count(:include => [:patient], :conditions => [" \
      start_date >= ? AND \
      start_date <= ? AND \
      death_date >= start_date AND \
      death_date < DATE_ADD(start_date, INTERVAL 1 MONTH)", @start_date, @end_date])

    second_month = PatientStartDate.count(:include => [:patient], :conditions => [" \
      start_date >= ? AND \
      start_date <= ? AND \
      death_date >= DATE_ADD(start_date, INTERVAL 1 MONTH) AND \
      death_date < DATE_ADD(start_date, INTERVAL 2 MONTH)", @start_date, @end_date])

    third_month = PatientStartDate.count(:include => [:patient], :conditions => [" \
      start_date >= ? AND \
      start_date <= ? AND \
      death_date >= DATE_ADD(start_date, INTERVAL 2 MONTH) AND \
      death_date < DATE_ADD(start_date, INTERVAL 3 MONTH)", @start_date, @end_date])

    after_third_month = PatientStartDate.count(:include => [:patient], :conditions => [" \
      start_date >= ? AND \
      start_date <= ? AND \
      death_date >= DATE_ADD(start_date, INTERVAL 3 MONTH) AND \
      death_date IS NOT NULL", @start_date, @end_date])
  
    [first_month, second_month, third_month, after_third_month]
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
    PatientStartDate.count(
      :joins => 
        "INNER JOIN ( \
          SELECT * FROM (
            SELECT * \
            FROM obs \
            WHERE obs_datetime >= '#{@start_date.to_formatted_s}' AND obs_datetime <= '#{@end_date.to_formatted_s}' AND \
              concept_id = #{concept_id} AND #{field} IN (#{values.join(',')}) \
            ORDER BY obs_datetime DESC \
          ) as t GROUP BY patient_id \
        ) as observation ON observation.patient_id = patient_start_dates.patient_id",
      :conditions => ["start_date >= ? AND start_date <= ?", @start_date, @end_date])
  end
   
end
