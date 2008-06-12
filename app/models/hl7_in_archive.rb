class Hl7InArchive < OpenMRS
  set_table_name "hl7_in_archive"
#hl7_in_archive_id
  set_primary_key "hl7_in_archive_id"
end


### Original SQL Definition for hl7_in_archive #### 
#   `hl7_in_archive_id` int(11) NOT NULL auto_increment,
#   `hl7_source` int(11) NOT NULL default '0',
#   `hl7_source_key` varchar(255) default NULL,
#   `hl7_data` mediumtext NOT NULL,
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`hl7_in_archive_id`)
