require "composite_primary_keys"
class NotificationAlertRecipient < OpenMRS
  set_table_name "notification_alert_recipient"
  belongs_to :user, :foreign_key => :user_id
  belongs_to :notification_alert, :foreign_key => :alert_id
  set_primary_keys :alert_id, :user_id
end


### Original SQL Definition for notification_alert_recipient #### 
#   `alert_id` int(11) NOT NULL,
#   `user_id` int(11) NOT NULL,
#   `alert_read` int(1) NOT NULL default '0',
#   `date_changed` timestamp NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
#   PRIMARY KEY  (`alert_id`,`user_id`),
#   KEY `alert_read_by_user` (`user_id`),
#   KEY `id_of_alert` (`alert_id`),
#   CONSTRAINT `id_of_alert` FOREIGN KEY (`alert_id`) REFERENCES `notification_alert` (`alert_id`),
#   CONSTRAINT `alert_read_by_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
#  
