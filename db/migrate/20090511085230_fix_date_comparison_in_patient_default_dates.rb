class FixDateComparisonInPatientDefaultDates < ActiveRecord::Migration
  def self.up
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_default_dates;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_default_dates (patient_id, default_date) AS
  SELECT patient_id, default_date 
  FROM patient_adherence_dates 
  WHERE
  NOT EXISTS (SELECT * FROM obs 
              WHERE obs.concept_id = 28 AND obs.voided = 0 AND
                    obs.patient_id = patient_adherence_dates.patient_id AND
                    DATE(obs.obs_datetime) >= patient_adherence_dates.visit_date AND 
                    DATE(obs.obs_datetime) <= patient_adherence_dates.default_date) AND
  NOT EXISTS (SELECT * FROM obs 
              WHERE obs.value_coded <> 3 AND obs.voided = 0 AND
                    (obs.concept_id = 372 OR obs.concept_id = 367) AND
                    obs.patient_id = patient_adherence_dates.patient_id AND
                    DATE(obs.obs_datetime) >= patient_adherence_dates.visit_date AND 
                    DATE(obs.obs_datetime) <= patient_adherence_dates.default_date) AND
  NOT EXISTS (SELECT * FROM encounter
              INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
              INNER JOIN drug_order ON drug_order.order_id = orders.order_id
              INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
              INNER JOIN concept_set as arv_drug_concepts ON arv_drug_concepts.concept_set = 460 AND arv_drug_concepts.concept_id = drug.concept_id  
              WHERE encounter.encounter_type = 3 AND
                    encounter.patient_id = patient_adherence_dates.patient_id AND
                    DATE(encounter.encounter_datetime) > patient_adherence_dates.visit_date AND
                    DATE(encounter.encounter_datetime) <= patient_adherence_dates.default_date);
EOF

  end

  def self.down
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_default_dates;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_default_dates (patient_id, default_date) AS
  SELECT patient_id, default_date 
  FROM patient_adherence_dates 
  WHERE
  NOT EXISTS (SELECT * FROM obs 
              WHERE obs.voided = 0 AND
                    obs.concept_id = 28 AND
                    obs.patient_id = patient_adherence_dates.patient_id AND
                    obs.obs_datetime >= patient_adherence_dates.visit_date AND 
                    obs.obs_datetime <= patient_adherence_dates.default_date) AND
  NOT EXISTS (SELECT * FROM obs 
              WHERE obs.voided = 0 AND
                    obs.value_coded <> 3 AND
                    (obs.concept_id = 372 OR obs.concept_id = 367) AND
                    obs.patient_id = patient_adherence_dates.patient_id AND
                    obs.obs_datetime >= patient_adherence_dates.visit_date AND 
                    obs.obs_datetime <= patient_adherence_dates.default_date) AND
  NOT EXISTS (SELECT * FROM encounter
              INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
              INNER JOIN drug_order ON drug_order.order_id = orders.order_id
              INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
              INNER JOIN concept_set as arv_drug_concepts ON arv_drug_concepts.concept_set = 460 AND arv_drug_concepts.concept_id = drug.concept_id  
              WHERE encounter.encounter_type = 3 AND
                    encounter.patient_id = patient_adherence_dates.patient_id AND
                    encounter.encounter_datetime > patient_adherence_dates.visit_date AND
                    encounter.encounter_datetime <= patient_adherence_dates.default_date);
EOF


  end
end
