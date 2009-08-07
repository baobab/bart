class ConvertStartAndRegistrationDateViewsToTables < ActiveRecord::Migration
  def self.up
    
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_start_dates;
EOF
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_start_dates;
EOF
    create_table :patient_start_dates do |t|
      t.integer  :patient_id, :null => false
      t.datetime :start_date, :null => false
      t.integer  :age_at_initiation, :null => false
      t.timestamps
    end
    
    add_index :patient_start_dates, :patient_id
    add_index :patient_start_dates, :start_date
    
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_registration_dates;
EOF
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_registration_dates;
EOF
    
    create_table :patient_registration_dates do |t|
      t.integer :patient_id, :null => false
      t.integer :location_id, :null => false
      t.date    :registration_date, :null => false
      t.timestamps
    end
    
    add_index :patient_registration_dates, :patient_id
    add_index :patient_registration_dates, :registration_date
  end

  def self.down
    drop_table :patient_registration_dates
    drop_table :patient_start_dates

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_registration_dates;
EOF
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_registration_dates;
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


  end
end
