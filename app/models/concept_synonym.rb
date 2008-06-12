require "composite_primary_keys"
class ConceptSynonym < OpenMRS
  set_table_name "concept_synonym"
  belongs_to :concept, :foreign_key => :concept_id
  belongs_to :user, :foreign_key => :user_id
  set_primary_keys :synonym, :concept_id
end


### Original SQL Definition for concept_synonym #### 
#   `concept_id` int(11) NOT NULL default '0',
#   `synonym` varchar(255) NOT NULL default '',
#   `locale` varchar(255) default NULL,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`synonym`,`concept_id`),
#   KEY `synonym_for` (`concept_id`),
#   KEY `synonym_creator` (`creator`),
#   CONSTRAINT `synonym_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `synonym_for` FOREIGN KEY (`concept_id`) REFERENCES `concept` (`concept_id`)
