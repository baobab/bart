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
  SELECT encounter.patient_id, encounter.encounter_id, encounter.encounter_datetime
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

  end

  def self.down
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_arv_drug_regimen_dispensations;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_dispensations_and_initiation_dates;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_dispensations_and_initiation_dates (patient_id, start_date) AS
   SELECT patient_id, dispensed_date AS start_date 
   FROM patient_first_line_regimen_dispensations
   UNION SELECT patient_id, value_datetime AS start_date
   FROM obs
   WHERE concept_id = 143 AND obs.voided = 0;
EOF

  end

end
