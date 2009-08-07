class AddArvDrugRegimenDispensations < ActiveRecord::Migration
  def self.up
# Count all of the patients whose first 460 concept_set(Arv Drug) regimen disensation happened in the specified period
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_arv_drug_regimen_dispensations;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_arv_drug_regimen_dispensations;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_arv_drug_regimen_dispensations (patient_id, encounter_id, dispensed_date) AS
  SELECT encounter.patient_id, encounter.encounter_id, DATE(encounter.encounter_datetime)
  FROM encounter
    INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
    INNER JOIN drug_order ON drug_order.order_id = orders.order_id 
    INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
    INNER JOIN concept_set as arv_drug_concepts ON
      arv_drug_concepts.concept_set = 460 AND
      arv_drug_concepts.concept_id = drug.concept_id;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_dispensations_and_initiation_dates;
EOF
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_dispensations_and_initiation_dates;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_dispensations_and_initiation_dates (patient_id, start_date) AS
   SELECT patient_id, dispensed_date AS start_date 
   FROM patient_arv_drug_regimen_dispensations
   UNION SELECT patient_id, value_datetime AS start_date
   FROM obs
   WHERE concept_id = 143 AND obs.voided = 0;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_start_dates;
EOF
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_start_dates;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_start_dates (patient_id, start_date, age_at_initiation) AS
  SELECT 
    patient_dispensations_and_initiation_dates.patient_id, 
    MIN(start_date) AS start_date, 
    (YEAR(start_date) - YEAR(birthdate)) + IF(((MONTH(start_date) - MONTH(birthdate)) + IF((DAY(start_date) - DAY(birthdate)) < 0, -1, 0)) < 0, -1, 0) +
    (IF((birthdate_estimated = 1 AND MONTH(birthdate) = 7 AND DAY(birthdate) = 1 AND MONTH(start_date) < MONTH(birthdate)), 1, 0)) AS age_at_initiation 
  FROM patient_dispensations_and_initiation_dates
  INNER JOIN patient ON patient.patient_id = patient_dispensations_and_initiation_dates.patient_id
  GROUP BY patient_dispensations_and_initiation_dates.patient_id;
EOF

  end

  def self.down
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_arv_drug_regimen_dispensations;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_dispensations_and_initiation_dates;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_start_dates;
EOF

  end

end
