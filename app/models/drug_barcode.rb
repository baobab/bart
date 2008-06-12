class DrugBarcode < OpenMRS
  set_table_name "drug_barcodes"
  belongs_to :drug, :foreign_key => :drug_id
end

#
#DROP TABLE IF EXISTS `drug_barcodes`;
#CREATE TABLE `drug_barcodes` (
#  `id` int(11) NOT NULL auto_increment,
#  `drug_id` int(11) NOT NULL default '0',
#  `barcode` varchar(16) NOT NULL default '',
#  `quantity` int(11) default '0',
#  PRIMARY KEY  (`id`)
#) ENGINE=InnoDB DEFAULT CHARSET=utf8;

