class ReportObject < OpenMRS
  set_table_name "report_object"
  belongs_to :user, :foreign_key => :user_id
#report_object_id
  set_primary_key "report_object_id"
end


### Original SQL Definition for report_object #### 
#   `report_object_id` int(11) NOT NULL auto_increment,
#   `name` varchar(255) NOT NULL,
#   `description` varchar(1000) default NULL,
#   `report_object_type` varchar(255) NOT NULL,
#   `report_object_sub_type` varchar(255) NOT NULL,
#   `xml_data` text default NULL,
#   `creator` int(11) NOT NULL,
#   `date_created` datetime NOT NULL,
#   `changed_by` int(11) default NULL,
#   `date_changed` datetime default NULL,
#   `voided` tinyint(1) NOT NULL,
#   `voided_by` int(11) default NULL,
#   `date_voided` datetime default NULL,
#   `void_reason` varchar(255) default NULL,
#   PRIMARY KEY  (`report_object_id`),
#   KEY `report_object_creator` (`creator`),
#   KEY `user_who_changed_report_object` (`changed_by`),
#   KEY `user_who_voided_report_object` (`voided_by`),
#   CONSTRAINT `report_object_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_changed_report_object` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_voided_report_object` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
