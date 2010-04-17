class CreatePharmacies < ActiveRecord::Migration
  def self.up
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `pharmacy_obs`;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE `pharmacy_obs` (
  `pharmacy_module_id` int(11) NOT NULL auto_increment,
  `pharmacy_encounter_type` int(11) NOT NULL default 0,
  `drug_id` int(11) NOT NULL default 0,
  `value_numeric` double,
  `encounter_date` date NOT NULL default '0000-00-00',
  `creator` int(11) NOT NULL,
  `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
  `changed_by` int(11),
  `date_changed` datetime,
  `voided` tinyint(1) NOT NULL default 0,
  `voided_by` int(11),
  `date_voided` datetime,
  `void_reason` varchar(225),
  PRIMARY KEY(pharmacy_module_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
EOF
  end

end
