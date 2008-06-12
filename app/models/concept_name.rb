require "composite_primary_keys"
class ConceptName < OpenMRS
  set_table_name "concept_name"
  belongs_to :concept, :foreign_key => :concept_id
  belongs_to :user, :foreign_key => :user_id
  set_primary_keys :concept_id, :locale
end


### Original SQL Definition for concept_name #### 
#   `concept_id` int(11) NOT NULL default '0',
#   `name` varchar(255) NOT NULL default '',
#   `short_name` varchar(255) default NULL,
#   `description` text NOT NULL,
#   `locale` varchar(50) NOT NULL default '',
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`concept_id`,`locale`),
#   KEY `user_who_created_name` (`creator`),
#   CONSTRAINT `name_for_concept` FOREIGN KEY (`concept_id`) REFERENCES `concept` (`concept_id`),
#   CONSTRAINT `user_who_created_name` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
