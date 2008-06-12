class Hl7InError < OpenMRS
  set_table_name "hl7_in_error"
#hl7_in_error_id
  set_primary_key "hl7_in_error_id"
end


### Original SQL Definition for hl7_in_error #### 
#   `hl7_in_error_id` int(11) NOT NULL auto_increment,
#   `hl7_source` int(11) NOT NULL default '0',
#   `hl7_source_key` text,
#   `hl7_data` mediumtext NOT NULL,
#   `error` varchar(255) NOT NULL default '',
#   `error_details` text,
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`hl7_in_error_id`)
