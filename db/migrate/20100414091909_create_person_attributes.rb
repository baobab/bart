class CreatePersonAttributes < ActiveRecord::Migration
  def self.up
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `person_attribute`;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE `person_attribute` (
  `person_attribute_id` int(11) NOT NULL auto_increment,
  `person_id` int(11) NOT NULL default 0,
  `value` varchar(50) NOT NULL,
  `person_attribute_type_id` int(11) NOT NULL default 0,
  `creator` int(11) NOT NULL default 0,
  `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
  `changed_by` int(11),
  `date_changed` datetime,
  `voided` tinyint(1) NOT NULL default 0,
  `voided_by` int(11),
  `date_voided` datetime,
  `void_reason` varchar(225),
  PRIMARY KEY(person_attribute_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
EOF
  end

  def self.down
    drop_table :person_attributes
  end
end
