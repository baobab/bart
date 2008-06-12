class PatientName < OpenMRS
  set_table_name "patient_name"
  belongs_to :patient, :foreign_key => :patient_id
  belongs_to :user, :foreign_key => :user_id
#patient_name_id
  set_primary_key "patient_name_id"
end


### Original SQL Definition for patient_name #### 
#   `patient_name_id` int(11) NOT NULL auto_increment,
#   `preferred` tinyint(1) NOT NULL default '0',
#   `patient_id` int(11) NOT NULL default '0',
#   `prefix` varchar(50) default NULL,
#   `given_name` varchar(50) default NULL,
#   `middle_name` varchar(50) default NULL,
#   `family_name_prefix` varchar(50) default NULL,
#   `family_name` varchar(50) default NULL,
#   `family_name2` varchar(50) default NULL,
#   `family_name_suffix` varchar(50) default NULL,
#   `degree` varchar(50) default NULL,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `voided` tinyint(1) NOT NULL default '0',
#   `voided_by` int(11) default NULL,
#   `date_voided` datetime default NULL,
#   `void_reason` varchar(255) default NULL,
#   `changed_by` int(11) default NULL,
#   `date_changed` datetime default NULL,
#   PRIMARY KEY  (`patient_name_id`),
#   KEY `name_for_patient` (`patient_id`),
#   KEY `user_who_made_name` (`creator`),
#   KEY `user_who_voided_name` (`voided_by`),
#   KEY `first_name` (`given_name`),
#   KEY `middle_name` (`middle_name`),
#   KEY `last_name` (`family_name`),
#   CONSTRAINT `name_for_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`),
#   CONSTRAINT `user_who_made_name` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_voided_name` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
