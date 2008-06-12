class ConceptClass < OpenMRS
  set_table_name "concept_class"
  has_many :concepts, :foreign_key => :class_id
  belongs_to :user, :foreign_key => :user_id
#concept_class_id
  set_primary_key "concept_class_id"
end


### Original SQL Definition for concept_class #### 
#   `concept_class_id` int(11) NOT NULL auto_increment,
#   `name` varchar(255) NOT NULL default '',
#   `description` varchar(255) NOT NULL default '',
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`concept_class_id`),
#   KEY `concept_class_creator` (`creator`),
#   CONSTRAINT `concept_class_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
