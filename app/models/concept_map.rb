class ConceptMap < OpenMRS
  set_table_name "concept_map"
  belongs_to :concept_source, :foreign_key => :concept_source_id
  belongs_to :user, :foreign_key => :user_id
#concept_map_id
  set_primary_key "concept_map_id"
end


### Original SQL Definition for concept_map #### 
#   `concept_map_id` int(11) NOT NULL auto_increment,
#   `source` int(11) default NULL,
#   `source_id` int(11) default NULL,
#   `comment` varchar(255) default NULL,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`concept_map_id`),
#   KEY `map_source` (`source`),
#   KEY `map_creator` (`creator`),
#   CONSTRAINT `map_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `map_source` FOREIGN KEY (`source`) REFERENCES `concept_source` (`concept_source_id`)
