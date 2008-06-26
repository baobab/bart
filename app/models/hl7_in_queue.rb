class Hl7InQueue < OpenMRS
  set_table_name "hl7_in_queue"
#  belongs_to :hl7_source, :foreign_key => :hl7_source
#hl7_in_queue_id
  set_primary_key "hl7_in_queue_id"
end


### Original SQL Definition for hl7_in_queue #### 
#   `hl7_in_queue_id` int(11) NOT NULL auto_increment,
#   `hl7_source` int(11) NOT NULL default '0',
#   `hl7_source_key` text,
#   `hl7_data` mediumtext NOT NULL,
#   `state` int(11) NOT NULL default '0' COMMENT '0=pending, 1=processing, 2=processed, 3=error',
#   `date_processed` datetime default NULL,
#   `error_msg` text,
#   `date_created` datetime default NULL,
#   PRIMARY KEY  (`hl7_in_queue_id`),
#   KEY `hl7_source` (`hl7_source`),
#   CONSTRAINT `hl7_source` FOREIGN KEY (`hl7_source`) REFERENCES `hl7_source` (`hl7_source_id`)
