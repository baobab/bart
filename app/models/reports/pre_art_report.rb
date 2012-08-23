
class Reports::PreARTReport

  def initialize(start_date, end_date)                                          
    @start_date = "#{start_date.to_date.to_s} 00:00:00"                                      
    @end_date = "#{end_date.to_date.to_s} 23:59:59"
    @cumulative_start = '1900-01-01 00:00:00'
  end 

  def total_registered(start_date = @start_date , end_date = @end_date)
    hiv_staging = EncounterType.find_by_name('HIV staging').id
    results = ActiveRecord::Base.connection.select_all <<EOF
SELECT p.* FROM patient p 
INNER JOIN encounter e ON p.patient_id = e.patient_id 
INNER JOIN obs ON e.encounter_id = obs.encounter_id WHERE obs.voided=0 
AND encounter_type = #{hiv_staging} AND e.encounter_datetime >= '#{start_date}' 
AND e.encounter_datetime <= '#{end_date}'
AND e.patient_id NOT IN(
SELECT patient_id FROM patient_registration_dates r 
WHERE r.`registration_date` >= '#{@cumulative_start}' 
AND r.`registration_date` <= '#{end_date}')
GROUP BY e.patient_id
ORDER BY MAX(e.encounter_datetime) DESC
EOF

    results.collect{|p|Patient.find(p['patient_id'])}
  end

  def cumulative_total_registered
    total_registered(@cumulative_start,@end_date)
  end

  def quarterly_total_registered
    total_registered(@start_date,@end_date)
  end

  def quarterly_total_patients_enrolled_first_time
    ids = quarterly_total_registered.collect{|p|p.id}
    art_initiation = EncounterType.find_by_name('HIV First visit').id
    ever_registered = Concept.find_by_name('Ever registered at ART clinic').id
    no_concept = Concept.find_by_name('NO').id

    results = ActiveRecord::Base.connection.select_all <<EOF
SELECT p.* FROM patient p 
INNER JOIN encounter e ON p.patient_id = e.patient_id
INNER JOIN obs ON e.encounter_id = obs.encounter_id WHERE obs.voided=0 
AND encounter_type = #{art_initiation} AND e.encounter_datetime >= '#{@start_date}' 
AND e.encounter_datetime <= '#{@end_date}' AND obs.concept_id = #{ever_registered}
AND e.patient_id IN(#{ids.join(',')}) AND obs.value_coded = #{no_concept}
GROUP BY e.patient_id
ORDER BY MAX(e.encounter_datetime) DESC
EOF

    results.collect{|p|Patient.find(p['patient_id'])}
  end


  def cumulative_total_patients_enrolled_first_time
    ids = cumulative_total_registered.collect{|p|p.id}
    art_initiation = EncounterType.find_by_name('HIV First visit').id
    ever_registered = Concept.find_by_name('Ever registered at ART clinic').id
    no_concept = Concept.find_by_name('NO').id

    results = ActiveRecord::Base.connection.select_all <<EOF
SELECT p.* FROM patient p 
INNER JOIN encounter e ON p.patient_id = e.patient_id
INNER JOIN obs ON e.encounter_id = obs.encounter_id WHERE obs.voided=0 
AND encounter_type = #{art_initiation} AND e.encounter_datetime >= '#{@cumulative_start}' 
AND e.encounter_datetime <= '#{@end_date}' AND obs.concept_id = #{ever_registered}
AND e.patient_id IN(#{ids.join(',')}) AND obs.value_coded = #{no_concept}
GROUP BY e.patient_id
ORDER BY MAX(e.encounter_datetime) DESC
EOF

    results.collect{|p|Patient.find(p['patient_id'])}
  end

  def quarterly_total_patients_re_enrolled
    ids = quarterly_total_registered.collect{|p|p.id}
    art_initiation = EncounterType.find_by_name('HIV First visit').id
    ever_registered = Concept.find_by_name('Ever registered at ART clinic').id
    yes_concept = Concept.find_by_name('YES').id

    results = ActiveRecord::Base.connection.select_all <<EOF
SELECT p.* FROM patient p 
INNER JOIN encounter e ON p.patient_id = e.patient_id
INNER JOIN obs ON e.encounter_id = obs.encounter_id WHERE obs.voided=0 
AND encounter_type = #{art_initiation} AND e.encounter_datetime >= '#{@start_date}' 
AND e.encounter_datetime <= '#{@end_date}' AND obs.concept_id = #{ever_registered}
AND e.patient_id IN(#{ids.join(',')}) AND obs.value_coded = #{yes_concept}
GROUP BY e.patient_id
ORDER BY MAX(e.encounter_datetime) DESC
EOF

    results.collect{|p|Patient.find(p['patient_id'])}
  end


  def cumulative_total_patients_re_enrolled
    ids = cumulative_total_registered.collect{|p|p.id}
    art_initiation = EncounterType.find_by_name('HIV First visit').id
    ever_registered = Concept.find_by_name('Ever registered at ART clinic').id
    yes_concept = Concept.find_by_name('YES').id

    results = ActiveRecord::Base.connection.select_all <<EOF
SELECT p.* FROM patient p 
INNER JOIN encounter e ON p.patient_id = e.patient_id
INNER JOIN obs ON e.encounter_id = obs.encounter_id WHERE obs.voided=0 
AND encounter_type = #{art_initiation} AND e.encounter_datetime >= '#{@cumulative_start}' 
AND e.encounter_datetime <= '#{@end_date}' AND obs.concept_id = #{ever_registered}
AND e.patient_id IN(#{ids.join(',')}) AND obs.value_coded = #{yes_concept}
GROUP BY e.patient_id
ORDER BY MAX(e.encounter_datetime) DESC
EOF

    results.collect{|p|Patient.find(p['patient_id'])}
  end


  def quarterly_total_registered_males
    quarterly_total_registered.collect{|p|p if p.gender == 'Male'}.compact rescue []
  end
  
  def cumulative_total_registered_males
    cumulative_total_registered.collect{|p|p if p.gender == 'Male'}.compact rescue []
  end
  
  def quarterly_total_registered_females
    quarterly_total_registered.collect{|p|p if p.gender == 'Female'}.compact rescue []
  end
  
  def cumulative_total_registered_females
    cumulative_total_registered.collect{|p|p if p.gender == 'Female'}.compact rescue []
  end

  def quarterly_pregnant_females
    ids = quarterly_total_registered_females.collect{|p|p.id if p.gender == 'Female'}.compact rescue []
    pregnant_concept = Concept.find_by_name('Pregnant').id
    yes_concept = Concept.find_by_name('YES').id

    ids = [0] if ids.blank?

    results = ActiveRecord::Base.connection.select_all <<EOF
SELECT p.* FROM patient p 
INNER JOIN obs ON obs.patient_id = p.patient_id WHERE obs.voided=0 
AND concept_id = #{pregnant_concept} AND obs_datetime >= '#{@start_date}' 
AND obs_datetime <= '#{@end_date}' AND obs.patient_id IN(#{ids.join(',')}) 
AND obs.value_coded = #{yes_concept} GROUP BY obs.patient_id
ORDER BY MAX(obs_datetime) DESC
EOF

    results.collect{|p|Patient.find(p['patient_id'])}

  end
  
  def cumulative_pregnant_females
    ids = cumulative_total_registered_females.collect{|p|p.id if p.gender == 'Female'}.compact rescue []
    pregnant_concept = Concept.find_by_name('Pregnant').id
    yes_concept = Concept.find_by_name('YES').id

    ids = [0] if ids.blank?

    results = ActiveRecord::Base.connection.select_all <<EOF
SELECT p.* FROM patient p 
INNER JOIN obs ON obs.patient_id = p.patient_id WHERE obs.voided=0 
AND concept_id = #{pregnant_concept} AND obs_datetime >= '#{@cumulative_start}' 
AND obs_datetime <= '#{@end_date}' AND obs.patient_id IN(#{ids.join(',')}) 
AND obs.value_coded = #{yes_concept} GROUP BY obs.patient_id
ORDER BY MAX(obs_datetime) DESC
EOF

    results.collect{|p|Patient.find(p['patient_id'])}

  end
  
  def quarterly_non_pregnant_females
    (quarterly_total_registered_females - quarterly_pregnant_females)    
  end
  
  def cumulative_non_pregnant_females
    (cumulative_total_registered_females - cumulative_pregnant_females)    
  end
  
  def age_at_initiation(age = '15 years', start_date = @start_date , end_date = @end_date)
    hiv_staging = EncounterType.find_by_name('HIV staging').id
    results = ActiveRecord::Base.connection.select_all <<EOF
SELECT p.patient_id AS patient_id,DATE(e.encounter_datetime) encounter_date,
age(p.birthdate,DATE(e.encounter_datetime),DATE(p.date_created),p.birthdate_estimated) 
AS age_at_initiation FROM patient p 
INNER JOIN encounter e ON p.patient_id = e.patient_id 
INNER JOIN obs ON e.encounter_id = obs.encounter_id WHERE obs.voided=0 
AND encounter_type = #{hiv_staging} AND e.encounter_datetime >= '#{start_date}' 
AND e.encounter_datetime <= '#{end_date}'
AND e.patient_id NOT IN(
SELECT patient_id FROM patient_registration_dates r 
WHERE r.`registration_date` >= '#{@cumulative_start}' 
AND r.`registration_date` <= '#{end_date}')
GROUP BY e.patient_id
ORDER BY MAX(e.encounter_datetime) DESC
EOF


    if age == "15 years"
      results.collect{|p|
        age_at_initiation = p['age_at_initiation'].to_i
        next if age_at_initiation < 15
        Patient.find(p['patient_id']) 
      }.compact
    elsif age == "24 months - 14yrs"
      results.collect{|p|
        age_at_initiation = p['age_at_initiation'].to_i
        next if not (age_at_initiation >= 2 and age_at_initiation < 15)
        Patient.find(p['patient_id']) 
      }.compact
    elsif age == "2 months - 24 months"
      results.collect{|p|
        age_at_initiation = p['age_at_initiation'].to_i
        next if age_at_initiation > 2
        patient = Patient.find(p['patient_id']) 
        age_in_months = patient.age_in_months(p['encounter_date'])
        next if not age_in_months >= 2 and not age_in_months <= 24
        patient
      }.compact
    elsif age == "2 months"
      results.collect{|p|
        age_at_initiation = p['age_at_initiation'].to_i
        next if age_at_initiation > 1 
        patient = Patient.find(p['patient_id']) 
        age_in_months = patient.age_in_months(p['encounter_date'])
        next if not age_in_months < 2 
        patient
      }.compact
    else
      []
    end
  end

  def outcomes(start_date=@start_date, end_date= @end_date, outcome_end_date= @end_date)
    start_date = "#{start_date} 00:00:00" unless start_date == @start_date
    end_date = "#{end_date} 23:59:59" unless end_date == @end_date
    outcome_end_date = "#{outcome_end_date} 23:59:59" unless outcome_end_date == @end_date

    outcome_hash = Hash.new(0)

    patient_ids = total_registered(start_date, end_date).collect{|p|p.patient_id}.compact.join(',') rescue ''


    results = ActiveRecord::Base.connection.select_all <<EOF
             SELECT * FROM patient p
             INNER JOIN patient_historical_outcomes ON p.patient_id = patient_historical_outcomes.patient_id \
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
             AND p.patient_id IN(#{patient_ids})
             ORDER BY DATE(outcome_date) DESC, sort_weight 
EOF
raise
    results.collect{|p|Patient.find(p['patient_id'])}
  end 



end
