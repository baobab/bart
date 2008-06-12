class Hl7Source < OpenMRS
  set_table_name "hl7_source"
  has_many :hl7_in_queues, :foreign_key => :hl7_source
  belongs_to :user, :foreign_key => :user_id
#hl7_source_id
  set_primary_key "hl7_source_id"
end


### Original SQL Definition for hl7_source #### 
#   `hl7_source_id` int(11) NOT NULL auto_increment,
#   `name` varchar(255) NOT NULL default '',
#   `description` tinytext,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`hl7_source_id`),
#   KEY `creator` (`creator`),
#   CONSTRAINT `creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
