class CreatePatientHistoricalRegimens < ActiveRecord::Migration

  def self.up
ActiveRecord::Base.connection.execute <<EOF



DROP TABLE IF EXISTS `patient_historical_regimens`;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE `patient_historical_regimens` (
 `regimen_concept_id` int(11) NOT NULL default 0,     
 `patient_id` int(11) NOT NULL default 0,             
 `encounter_id` int(11) NOT NULL default 0,           
 `dispensed_date` datetime NOT NULL default '0000-00-00 00:00:00' 
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
EOF

 end


  def self.down
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `patient_historical_regimens`;
EOF

  end
end


