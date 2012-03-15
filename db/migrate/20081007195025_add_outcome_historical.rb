class AddOutcomeHistorical < ActiveRecord::Migration
  def self.up
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_historical_outcomes;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE patient_historical_outcomes (
  `id` int(11) NOT NULL auto_increment,
  `patient_id` int(11) NOT NULL,
  `outcome_concept_id` int(11) NOT NULL,
  `outcome_date` DATE NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `patient_id_outcome_concept_id_outcome_date` (`patient_id`, `outcome_concept_id`, `outcome_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF
  end

  def self.down
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_historical_outcomes;
EOF
  end
end
