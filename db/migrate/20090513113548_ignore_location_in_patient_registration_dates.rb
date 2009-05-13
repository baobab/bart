class IgnoreLocationInPatientRegistrationDates < ActiveRecord::Migration
  def self.up
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_registration_dates;
EOF

  # removed location_id from GROUP BY clause
ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_registration_dates (patient_id, location_id, registration_date) AS
  SELECT encounter.patient_id, encounter.location_id, MIN(encounter.encounter_datetime)
  FROM encounter
  INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
  INNER JOIN drug_order ON drug_order.order_id = orders.order_id
  INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
  INNER JOIN concept_set as arv_drug_concepts ON arv_drug_concepts.concept_set = 460 AND arv_drug_concepts.concept_id = drug.concept_id  
  WHERE encounter.encounter_type = 3
  GROUP BY patient_id;
EOF
  end

  def self.down
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_registration_dates;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_registration_dates (patient_id, location_id, registration_date) AS
  SELECT encounter.patient_id, encounter.location_id, MIN(encounter.encounter_datetime)
  FROM encounter
  INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
  INNER JOIN drug_order ON drug_order.order_id = orders.order_id
  INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
  INNER JOIN concept_set as arv_drug_concepts ON arv_drug_concepts.concept_set = 460 AND arv_drug_concepts.concept_id = drug.concept_id  
  WHERE encounter.encounter_type = 3
  GROUP BY patient_id, location_id;
EOF
  end
end
