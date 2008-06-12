class NotificationTemplate < OpenMRS
  set_table_name "notification_template"
#
  set_primary_key ""
end


### Original SQL Definition for notification_template ####  
#    `template_id` int(11) NOT NULL auto_increment,
#    `name` varchar(50),
#    `template` text,
#    `subject` varchar(100) default NULL,
#    `sender` varchar(255) default NULL,
#    `recipients` varchar(512) default NULL,
#    `ordinal` int(11) default 0,
#    primary key (`template_id`)
#  
