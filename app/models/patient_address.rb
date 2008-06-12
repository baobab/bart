class PatientAddress < OpenMRS
  set_table_name "patient_address"
  belongs_to :patient, :foreign_key => :patient_id
  belongs_to :user, :foreign_key => :user_id
#patient_address_id
  set_primary_key "patient_address_id"
end


### Original SQL Definition for patient_address #### 
#   `patient_address_id` int(11) NOT NULL auto_increment,
#   `patient_id` int(11) NOT NULL default '0',
#   `preferred` tinyint(1) NOT NULL default '0',
#   `address1` varchar(50) default NULL,
#   `address2` varchar(50) default NULL,
#   `city_village` varchar(50) default NULL,
#   `state_province` varchar(50) default NULL,
#   `postal_code` varchar(50) default NULL,
#   `country` varchar(50) default NULL,
#   `latitude` varchar(50) default NULL,
#   `longitude` varchar(50) default NULL,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `voided` tinyint(1) NOT NULL default '0',
#   `voided_by` int(11) default NULL,
#   `date_voided` datetime default NULL,
#   `void_reason` varchar(255) default NULL,
#   PRIMARY KEY  (`patient_address_id`),
#   KEY `patient_address_creator` (`creator`),
#   KEY `patient_addresses` (`patient_id`),
#   KEY `patient_address_void` (`voided_by`),
#   CONSTRAINT `patient_addresses` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`),
#   CONSTRAINT `patient_address_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `patient_address_void` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
