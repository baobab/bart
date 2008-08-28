class CreateWeightForHeight < ActiveRecord::Migration
  def self.up
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `weight_for_heights`;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE `weight_for_heights` (
  `id` int(11) NOT NULL auto_increment,
  `supinecm` float default NULL,
  `median_weight_height` float default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `weight_height_for_ages`;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE `weight_height_for_ages` (
  `age_in_months` smallint(6) default NULL,
  `sex` char(12) default NULL,
  `median_height` double default NULL,
  `standard_low_height` double default NULL,
  `standard_high_height` double default NULL,
  `median_weight` double default NULL,
  `standard_low_weight` double default NULL,
  `standard_high_weight` double default NULL,
  `age_sex` char(4) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
EOF
  end

  def self.down
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `weight_for_heights`;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `weight_height_for_ages`;
EOF
  end
end
