class FixDefaultDatesForNullPillCounts < ActiveRecord::Migration
  def self.up
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
INSERT INTO patient_adherence_dates (patient_id, drug_id, visit_date, drugs_run_out_date, default_date)
  SELECT patient_id, 
         drug_id, 
         visit_date, 
         ADDDATE(visit_date, INTERVAL IFNULL(((IFNULL(total_remaining,0) + total_dispensed) / IFNULL(daily_consumption,2)), 30) DAY) as drugs_run_out_date,
         ADDDATE(visit_date, INTERVAL IFNULL(((IFNULL(total_remaining,0) + total_dispensed) / IFNULL(daily_consumption,2)), 30) + 60 DAY) as default_date
  FROM patient_dispensations_and_prescriptions;
EOF
  end

  def self.down
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
INSERT INTO patient_adherence_dates (patient_id, drug_id, visit_date, drugs_run_out_date, default_date)
  SELECT patient_id, 
         drug_id, 
         visit_date, 
         ADDDATE(visit_date, INTERVAL IFNULL(((total_remaining + total_dispensed) / daily_consumption), 30) DAY) as drugs_run_out_date,
         ADDDATE(visit_date, INTERVAL IFNULL(((total_remaining + total_dispensed) / daily_consumption), 30) + 60 DAY) as default_date
  FROM patient_dispensations_and_prescriptions;
EOF
  end
end
