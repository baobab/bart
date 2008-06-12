class RelationshipType < OpenMRS
  set_table_name "relationship_type"
  has_many :relationships, :foreign_key => :relationship
  belongs_to :user, :foreign_key => :user_id
#relationship_type_id
  set_primary_key "relationship_type_id"
end


### Original SQL Definition for relationship_type #### 
#   `relationship_type_id` int(11) NOT NULL auto_increment,
#   `name` varchar(50) NOT NULL default '',
#   `description` varchar(255) NOT NULL default '',
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`relationship_type_id`),
#   KEY `user_who_created_rel` (`creator`),
#   CONSTRAINT `user_who_created_rel` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
