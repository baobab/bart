class CreateAllDrugOrderCombinations < ActiveRecord::Migration
  def self.up
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `drug_order_combination_regimen`;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE `drug_order_combination_regimen` (
  `name` varchar(255) NOT NULL,
  `creator` int default NULL,
  `drug_order_combination_regimen_id` int NOT NULL,
  `date_created` datetime default NULL,
  PRIMARY KEY  (`drug_order_combination_regimen_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `drug_order_combination`;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE TABLE `drug_order_combination` (
  `drug_order_combination_id` int NOT NULL,
  `min_weight` double NOT NULL,
  `max_weight` double NOT NULL,
  `drug_id` int NOT NULL,
  `frequency` char(15) NOT NULL,
  `units` double NOT NULL,
  `creator` int default NULL,
  `drug_order_combination_regimen_id` int NOT NULL,
  `date_created` datetime default NULL,
  PRIMARY KEY  (`drug_order_combination_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
EOF


  end

  def self.down
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `drug_order_combination_regimen`;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `drug_order_combination`;
EOF

  end
end
