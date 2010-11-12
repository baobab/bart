class AddIndicesToPatientHistoricalRegimens < ActiveRecord::Migration
  def self.up

    ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `patient_historical_regimens`;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE `patient_historical_regimens` (
  `id` int(11) NOT NULL auto_increment,
  `regimen_concept_id` int(11) NOT NULL default 0,
  `patient_id` int(11) NOT NULL default 0,
  `encounter_id` int(11) NOT NULL default 0,
  `dispensed_date` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`),
  KEY `patient_id` (`patient_id`),
  KEY `regimen_concept_id` (`regimen_concept_id`),
  KEY `encounter_id` (`encounter_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
EOF

    PatientHistoricalRegimen.reset

  end

  def self.down

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `patient_historical_regimens`;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE `patient_historical_regimens` (
  `regimen_concept_id` int(11) NOT NULL default 0,
  `patient_id` int(11) NOT NULL default 0,
  `encounter_id` int(11) NOT NULL default 0,
  `dispensed_date` datetime NOT NULL default '0000-00-00 00:00:00',
  KEY `patient_id` (`patient_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
EOF

    PatientHistoricalRegimen.reset
  end
end
