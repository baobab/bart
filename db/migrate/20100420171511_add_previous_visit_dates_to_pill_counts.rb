class AddPreviousVisitDatesToPillCounts < ActiveRecord::Migration
  def self.up
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_whole_tablets_remaining_and_brought;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE patient_whole_tablets_remaining_and_brought (
  `id` int(11) NOT NULL auto_increment,
  `patient_id` int(11) NOT NULL,
  `drug_id` int(11) NOT NULL,
  `visit_date` DATE NOT NULL,
  `total_remaining` int(11) DEFAULT NULL,
  `previous_visit_date` DATE,
  PRIMARY KEY  (`id`),
  KEY `patient_id_drug_id_presciption_date` (`patient_id`, `drug_id`, `visit_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF
  end

  def self.down
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

  end

end
