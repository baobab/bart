class PatientProgram < OpenMRS
  set_table_name "patient_program"
  set_primary_key "patient_program_id"
  belongs_to :patient, :foreign_key => :patient_id
  belongs_to :program, :foreign_key => :program_id
end


#DROP TABLE IF EXISTS `patient_program`;
#CREATE TABLE `patient_program` (
#  `patient_program_id` int(11) NOT NULL auto_increment,
#  `patient_id` int(11) NOT NULL default '0',
#  `program_id` int(11) NOT NULL default '0',
#  `date_enrolled` datetime default NULL,
#  `date_completed` datetime default NULL,
#  `creator` int(11) NOT NULL default '0',
#  `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#  `changed_by` int(11) default NULL,
#  `date_changed` datetime default NULL,
#  `voided` tinyint(1) NOT NULL default '0',
#  `voided_by` int(11) default NULL,
#  `date_voided` datetime default NULL,
#  `void_reason` varchar(255) default NULL,
#  PRIMARY KEY  (`patient_program_id`),
#  KEY `patient_in_program` (`patient_id`),
#  KEY `program_for_patient` (`program_id`),
#  KEY `patient_program_creator` (`creator`),
#  KEY `user_who_changed` (`changed_by`),
#  KEY `user_who_voided_patient_program` (`voided_by`),
#  CONSTRAINT `patient_in_program` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON UPDATE CASCADE,
#  CONSTRAINT `patient_program_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#  CONSTRAINT `program_for_patient` FOREIGN KEY (`program_id`) REFERENCES `program` (`program_id`),
#  CONSTRAINT `user_who_changed` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`),
#  CONSTRAINT `user_who_voided_patient_program` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
#) ENGINE=InnoDB DEFAULT CHARSET=utf8;
