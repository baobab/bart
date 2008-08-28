class AddPrescriptions < ActiveRecord::Migration
  def self.up
# Good chance this should be in the fixtures
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS prescription_time_periods;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE prescription_time_periods (
  `id` int(11) NOT NULL auto_increment,
  `time_period` varchar(255) NOT NULL,
  `time_period_days` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `time_period_index` (`time_period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF

#This applies the appropriate buffer period
ActiveRecord::Base.connection.execute <<EOF
INSERT INTO prescription_time_periods (time_period, time_period_days) VALUES
  ('2 weeks', 15),
  ('1 month', 30),
  ('2 months', 58),
  ('3 months', 86),
  ('4 months', 114),
  ('5 months', 142),
  ('6 months', 170);
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS prescription_frequencies;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE prescription_frequencies (
  `id` int(11) NOT NULL auto_increment,
  `frequency` varchar(255) NOT NULL,
  `frequency_days` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `frequency_index` (`frequency`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF

ActiveRecord::Base.connection.execute <<EOF
INSERT INTO prescription_frequencies (frequency, frequency_days) VALUES
  ('Once', 1),
  ('Morning', 1),
  ('Evening', 1),
  ('Weekly', 7);
EOF

# Eventually prescription time periods should be value_coded
# Eventually prescription frequencies should be value_coded
# 375 = Concept "Prescribed dose"
# 345 = Concept "Presription time period"
# 363 = Concept "Whole tablets remaining and brought to clinic"
# 2 = Encounter Type "ART Visit"
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_prescriptions;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_prescriptions (patient_id, encounter_id, prescription_datetime, drug_id, frequency, dose_amount, time_period, quantity, daily_consumption) AS
  SELECT encounter.patient_id, 
         encounter.encounter_id, 
         prescribed_dose.obs_datetime, 
         prescribed_dose.value_drug,
         prescribed_dose.value_text,
         prescribed_dose.value_numeric,
         prescribed_time_period.value_text,
         (prescribed_dose.value_numeric * (prescription_time_periods.time_period_days / prescription_frequencies.frequency_days)),
         (prescribed_dose.value_numeric / prescription_frequencies.frequency_days)
  FROM encounter
  INNER JOIN obs AS prescribed_dose ON 
    prescribed_dose.concept_id = 375 AND 
    prescribed_dose.encounter_id = encounter.encounter_id AND 
    prescribed_dose.value_drug IS NOT NULL AND 
    prescribed_dose.voided = 0
  INNER JOIN obs AS prescribed_time_period ON 
    prescribed_time_period.concept_id = 345 AND
    prescribed_time_period.encounter_id = encounter.encounter_id AND 
    prescribed_time_period.voided = 0
  INNER JOIN prescription_frequencies ON prescription_frequencies.frequency = prescribed_dose.value_text  
  INNER JOIN prescription_time_periods ON prescription_time_periods.time_period = prescribed_time_period.value_text  
  WHERE encounter.encounter_type = 2;
EOF
  end

  def self.down
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS prescription_time_periods;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS prescription_frequencies;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_prescriptions;
EOF
  end
end
