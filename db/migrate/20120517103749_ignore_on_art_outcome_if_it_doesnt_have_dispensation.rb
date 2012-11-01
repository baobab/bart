class IgnoreOnArtOutcomeIfItDoesntHaveDispensation < ActiveRecord::Migration
  def self.up
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_outcomes;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_outcomes;
EOF


ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_outcomes (patient_id, outcome_date, outcome_concept_id) AS
  SELECT encounter.patient_id, encounter.encounter_datetime, 324
  FROM encounter
  INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
  INNER JOIN drug_order ON drug_order.order_id = orders.order_id 
  INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
  INNER JOIN concept_set as arv_drug_concepts ON
    arv_drug_concepts.concept_set = 460 AND
    arv_drug_concepts.concept_id = drug.concept_id
  UNION
  SELECT obs.patient_id, obs.obs_datetime, obs.value_coded 
  FROM obs 
  WHERE obs.concept_id = 28 AND obs.voided = 0 AND obs.value_coded <> 324
  UNION
  SELECT obs.patient_id, obs.obs_datetime, 325 
  FROM obs 
  WHERE obs.concept_id = 372 AND obs.value_coded <> 3 AND obs.voided = 0
  UNION
  SELECT obs.patient_id, obs.obs_datetime, 386 
  FROM obs 
  WHERE obs.concept_id = 367 AND obs.value_coded <> 3 AND obs.voided = 0
  UNION
  SELECT patient_default_dates.patient_id, patient_default_dates.default_date, 373
  FROM patient_default_dates 
  WHERE patient_default_dates.default_date < CURRENT_DATE()
  UNION
  SELECT patient.patient_id, patient.death_date, 322
  FROM patient
  WHERE patient.death_date IS NOT NULL;
EOF
  end

  def self.down
  ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_outcomes;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_outcomes;
EOF


ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_outcomes (patient_id, outcome_date, outcome_concept_id) AS
  SELECT encounter.patient_id, encounter.encounter_datetime, 324
  FROM encounter
  INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
  INNER JOIN drug_order ON drug_order.order_id = orders.order_id 
  INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
  INNER JOIN concept_set as arv_drug_concepts ON
    arv_drug_concepts.concept_set = 460 AND
    arv_drug_concepts.concept_id = drug.concept_id
  UNION
  SELECT obs.patient_id, obs.obs_datetime, obs.value_coded 
  FROM obs 
  WHERE obs.concept_id = 28 AND obs.voided = 0
  UNION
  SELECT obs.patient_id, obs.obs_datetime, 325 
  FROM obs 
  WHERE obs.concept_id = 372 AND obs.value_coded <> 3 AND obs.voided = 0
  UNION
  SELECT obs.patient_id, obs.obs_datetime, 386 
  FROM obs 
  WHERE obs.concept_id = 367 AND obs.value_coded <> 3 AND obs.voided = 0
  UNION
  SELECT patient_default_dates.patient_id, patient_default_dates.default_date, 373
  FROM patient_default_dates 
  WHERE patient_default_dates.default_date < CURRENT_DATE()
  UNION
  SELECT patient.patient_id, patient.death_date, 322
  FROM patient
  WHERE patient.death_date IS NOT NULL;
EOF
  end
end
