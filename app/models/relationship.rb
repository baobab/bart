class Relationship < OpenMRS
  set_table_name "relationship"
  belongs_to :type, :foreign_key => :relationship_type_id
  belongs_to :user, :foreign_key => :user_id
  belongs_to :person, :foreign_key => :person_id
  belongs_to :relative, :class_name => "Person", :foreign_key => :relative_id
#relationship_id
  set_primary_key "relationship_id"
end


### Original SQL Definition for relationship #### 
#   `relationship_id` int(11) NOT NULL auto_increment,
#   `person_id` int(11) NOT NULL default '0',
#   `relationship` int(11) NOT NULL default '0',
#   `relative_id` int(11) NOT NULL default '0',
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `voided` tinyint(1) NOT NULL default '0',
#   `voided_by` int(11) default NULL,
#   `date_voided` datetime default NULL,
#   `void_reason` varchar(255) default NULL,
#   PRIMARY KEY  (`relationship_id`),
#   KEY `related_person` (`person_id`),
#   KEY `related_relative` (`relative_id`),
#   KEY `relationship_type` (`relationship`),
#   KEY `relation_creator` (`creator`),
#   KEY `relation_voider` (`voided_by`),
#   CONSTRAINT `relationship_type_id` FOREIGN KEY (`relationship`) REFERENCES `relationship_type` (`relationship_type_id`),
#   CONSTRAINT `related_person` FOREIGN KEY (`person_id`) REFERENCES `person` (`person_id`),
#   CONSTRAINT `related_relative` FOREIGN KEY (`relative_id`) REFERENCES `person` (`person_id`),
#   CONSTRAINT `relation_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `relation_voider` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
