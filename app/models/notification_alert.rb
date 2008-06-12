class NotificationAlert < OpenMRS
  set_table_name "notification_alert"
  has_many :notification_alert_recipients, :foreign_key => :alert_id
  belongs_to :user, :foreign_key => :user_id
#alert_id
  set_primary_key "alert_id"
end


### Original SQL Definition for notification_alert #### 
#   `alert_id` int(11) NOT NULL auto_increment,
#   `text` varchar(512) NOT NULL,
#   `satisfied_by_any` int(1) NOT NULL default '0',
#   `alert_read` int(1) NOT NULL default '0',
#   `date_to_expire` datetime default NULL,
#   `creator` int(11) NOT NULL,
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `changed_by` int(11) default NULL,
#   `date_changed` datetime default NULL,
#   PRIMARY KEY  (`alert_id`),
#   KEY `alert_creator` (`creator`),
#   KEY `user_who_changed_alert` (`changed_by`),
#   CONSTRAINT `alert_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_changed_alert` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`)
#  
