class AddPatientAdherenceRates < ActiveRecord::Migration
  def self.up

    ActiveRecord::Base.connection.execute <<EOF
      DROP TABLE IF EXISTS tmp_patient_dispensations_and_prescriptions;
EOF

    ActiveRecord::Base.connection.execute <<EOF
      DROP TABLE IF EXISTS patient_adherence_rates;
EOF

    ActiveRecord::Base.connection.execute <<EOF
      CREATE TABLE `tmp_patient_dispensations_and_prescriptions` (
        `patient_id` int(11) NOT NULL default '0',
        `encounter_id` int(11) NOT NULL default '0',
        `visit_date` DATE,
        `drug_id` int(11) NOT  NULL default '0',
        `total_dispensed` decimal(32,0),
        `total_remaining` int(11),
        `daily_consumption` int(11),
        PRIMARY KEY(patient_id,encounter_id,visit_date,drug_id)
      ) ENGINE=MyISAM DEFAULT CHARSET=latin1;
EOF

    ActiveRecord::Base.connection.execute <<EOF
      INSERT INTO tmp_patient_dispensations_and_prescriptions  (
        SELECT * FROM patient_dispensations_and_prescriptions
      );
EOF

    ActiveRecord::Base.connection.execute <<EOF
      CREATE TABLE `patient_adherence_rates` (
        `id` int(11) NOT NULL auto_increment,
        `patient_id` int(11) NOT NULL default '0',
        `visit_date` DATE,
        `drug_id` int(11) NOT  NULL default '0',
        `expected_remaining` int(11),
        `adherence_rate` int(11),
        PRIMARY KEY(id),
        UNIQUE KEY `patient_visit_drug ON patient_adherence_rates` (`patient_id`,`visit_date`,`drug_id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
EOF

    ActiveRecord::Base.connection.execute <<EOF
      INSERT INTO patient_adherence_rates (patient_id,visit_date,drug_id,adherence_rate) 
        SELECT t1.patient_id, t1.visit_date, t1.drug_id,
          (SELECT 100*(SUM(total_dispensed)+SUM(total_remaining)-t1.total_remaining)/((SUM(total_dispensed)+SUM(total_remaining)) - (SUM(total_dispensed)+SUM(total_remaining) - (daily_consumption * DATEDIFF(t1.visit_date, t2.visit_date))))
           FROM tmp_patient_dispensations_and_prescriptions t2 WHERE t2.patient_id = t1.patient_id AND t2.drug_id = t1.drug_id AND t2.visit_date < t1.visit_date GROUP BY t2.patient_id,t2.visit_date DESC LIMIT 1) AS adherence_rate 
        FROM tmp_patient_dispensations_and_prescriptions t1
        GROUP BY patient_id, visit_date, drug_id;
EOF

  end

  def self.down
    ActiveRecord::Base.connection.execute <<EOF
      DROP TABLE IF EXISTS tmp_patient_dispensations_and_prescriptions;
EOF

    ActiveRecord::Base.connection.execute <<EOF
      DROP TABLE IF EXISTS patient_adherence_rates;
EOF
  end
end
