class FormentryQueue < OpenMRS
  set_table_name "formentry_queue"
#formentry_queue_id
  set_primary_key "formentry_queue_id"
end


### Original SQL Definition for formentry_queue #### 
#   `formentry_queue_id` int(11) NOT NULL auto_increment,
#   `form_data` mediumtext NOT NULL,
#   `status` int(11) NOT NULL default '0' COMMENT '0=pending, 1=processing, 2=processed, 3=error',
#   `date_processed` datetime default NULL,
#   `error_msg` varchar(255) default NULL,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`formentry_queue_id`)
