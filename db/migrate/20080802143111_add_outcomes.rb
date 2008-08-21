class AddOutcomes < ActiveRecord::Migration
  def self.up
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_prescription_totals;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE patient_prescription_totals (
  `id` int(11) NOT NULL auto_increment,
  `patient_id` int(11) NOT NULL,
  `drug_id` int(11) NOT NULL,
  `prescription_date` DATE NOT NULL,
  `daily_consumption` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `patient_id_drug_id_presciption_date` (`patient_id`, `drug_id`, `prescription_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_whole_tablets_remaining_and_brought;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE patient_whole_tablets_remaining_and_brought (
  `id` int(11) NOT NULL auto_increment,
  `patient_id` int(11) NOT NULL,
  `drug_id` int(11) NOT NULL,
  `visit_date` DATE NOT NULL,
  `total_remaining` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `patient_id_drug_id_presciption_date` (`patient_id`, `drug_id`, `visit_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_adherence_dates;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE patient_adherence_dates (
  `id` int(11) NOT NULL auto_increment,
  `patient_id` int(11) NOT NULL,
  `drug_id` int(11) NOT NULL,
  `visit_date` DATE NOT NULL,
  `drugs_run_out_date` DATE NOT NULL,
  `default_date` DATE NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `patient_id_visit_date_default_date` (`patient_id`, `visit_date`, `default_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_dispensations_and_prescriptions;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_dispensations_and_prescriptions (patient_id, encounter_id, visit_date, drug_id, total_dispensed, total_remaining, daily_consumption) AS
  SELECT encounter.patient_id, 
         encounter.encounter_id, 
         DATE(encounter.encounter_datetime),
         drug.drug_id,
         drug_order.quantity AS total_dispensed,
         whole_tablets_remaining_and_brought.total_remaining AS total_remaining,
         patient_prescription_totals.daily_consumption AS daily_consumption
  FROM encounter
  INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
  INNER JOIN drug_order ON drug_order.order_id = orders.order_id 
  INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
  INNER JOIN concept_set as arv_drug_concepts ON
    arv_drug_concepts.concept_set = 460 AND
    arv_drug_concepts.concept_id = drug.concept_id
  LEFT JOIN patient_whole_tablets_remaining_and_brought AS whole_tablets_remaining_and_brought ON
    whole_tablets_remaining_and_brought.patient_id = encounter.patient_id AND
    whole_tablets_remaining_and_brought.visit_date = DATE(encounter.encounter_datetime) AND    
    whole_tablets_remaining_and_brought.drug_id = drug.drug_id
  LEFT JOIN patient_prescription_totals ON   
    patient_prescription_totals.drug_id = drug.drug_id AND
    patient_prescription_totals.patient_id = encounter.patient_id AND
    patient_prescription_totals.prescription_date = DATE(encounter.encounter_datetime);
EOF

# Grab all of the possible default dates, then filter this
# (a) make sure that there does not exist an Outcome observation in between the visit date and potential default date
# (b) make sure that there does not exist ARV dispensation in between the visit date and potential default date
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_default_dates;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_default_dates (patient_id, default_date) AS
  SELECT patient_id, default_date 
  FROM patient_adherence_dates 
  WHERE
  NOT EXISTS (SELECT * FROM obs 
              WHERE obs.concept_id = 28 AND
                    obs.patient_id = patient_adherence_dates.patient_id AND
                    obs.obs_datetime >= patient_adherence_dates.visit_date AND 
                    obs.obs_datetime <= patient_adherence_dates.default_date) AND
  NOT EXISTS (SELECT * FROM obs 
              WHERE obs.value_coded <> 3 AND
                    (obs.concept_id = 372 OR obs.concept_id = 367) AND
                    obs.patient_id = patient_adherence_dates.patient_id AND
                    obs.obs_datetime >= patient_adherence_dates.visit_date AND 
                    obs.obs_datetime <= patient_adherence_dates.default_date) AND
  NOT EXISTS (SELECT * FROM encounter
              INNER JOIN orders ON orders.encounter_id = encounter.encounter_id
              INNER JOIN drug_order ON drug_order.order_id = orders.order_id
              INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
              INNER JOIN concept_set as arv_drug_concepts ON arv_drug_concepts.concept_set = 460 AND arv_drug_concepts.concept_id = drug.concept_id  
              WHERE encounter.encounter_type = 3 AND
                    encounter.patient_id = patient_adherence_dates.patient_id AND
                    encounter.encounter_datetime > patient_adherence_dates.visit_date AND
                    encounter.encounter_datetime <= patient_adherence_dates.default_date);
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_outcomes;
EOF

# <tt>On ART</tt> (Concept: 324)
# <tt>Transfer out</tt> (Concept: 325)
# <tt>Transfer Out(Without Transfer Note)</tt> (Concept: 383)
# <tt>ART Stop</tt> (Concept: 386)
# <tt>Defaulter</tt> (Concept: 373)
# <tt>Died</tt> (Concept: 322)
#
# <tt>Outcome</tt> (Concept: 28)
# <tt>Continue treatment at current clinic</tt> (Concept: 372)
# <tt>Continue ART</tt> (Concept: 367)
#
# <tt>Yes</tt> (Concept: 3)
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
  WHERE obs.concept_id = 28
  UNION
  SELECT obs.patient_id, obs.obs_datetime, 325 
  FROM obs 
  WHERE obs.concept_id = 372 AND obs.value_coded <> 3
  UNION
  SELECT obs.patient_id, obs.obs_datetime, 386 
  FROM obs 
  WHERE obs.concept_id = 367 AND obs.value_coded <> 3
  UNION
  SELECT patient_default_dates.patient_id, patient_default_dates.default_date, 373
  FROM patient_default_dates
  UNION
  SELECT patient.patient_id, patient.death_date, 322
  FROM patient
  WHERE patient.death_date IS NOT NULL;
EOF
  end

  def self.down
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_prescription_totals;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_whole_tablets_remaining_and_brought;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_adherence_dates;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_dispensations_and_prescriptions;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_default_dates;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_outcomes;
EOF
  end
end
