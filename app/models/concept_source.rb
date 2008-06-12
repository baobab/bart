class ConceptSource < OpenMRS
  set_table_name "concept_source"
  has_many :concept_maps, :foreign_key => :source
  belongs_to :user, :foreign_key => :user_id
#concept_source_id
  set_primary_key "concept_source_id"
end


### Original SQL Definition for concept_source #### 
#   `concept_source_id` int(11) NOT NULL auto_increment,
#   `name` varchar(50) NOT NULL default '',
#   `description` text NOT NULL,
#   `hl7_code` varchar(50) NOT NULL default '',
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `voided` tinyint(4) default NULL,
#   `voided_by` int(11) default NULL,
#   `date_voided` datetime default NULL,
#   `void_reason` varchar(255) default NULL,
#   PRIMARY KEY  (`concept_source_id`),
#   KEY `concept_source_creator` (`creator`),
#   KEY `user_who_voided_concept_source` (`voided_by`),
#   CONSTRAINT `concept_source_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_voided_concept_source` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
