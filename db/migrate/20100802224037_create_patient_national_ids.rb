class CreatePatientNationalIds < ActiveRecord::Migration

  def self.up

    ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE IF NOT EXISTS `patient_national_id` (
`id` INTEGER NOT NULL auto_increment,
`national_id` varchar(30) NOT NULL default '',
`assigned` tinyint(1) NOT NULL default 0,
PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=264255 DEFAULT CHARSET=latin1;
EOF

  end

  def self.down
    drop_table :patient_national_id
  end

end
