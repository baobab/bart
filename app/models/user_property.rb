require "composite_primary_keys"
class UserProperty < OpenMRS
  set_table_name "user_property"
  belongs_to :user, :foreign_key => :user_id
  set_primary_keys :user_id, :property
end


### Original SQL Definition for user_property #### 
#   `user_id` int(11) NOT NULL default '0',
#   `property` varchar(100) NOT NULL default '',
#   `property_value` varchar(255) NOT NULL default '',
#   PRIMARY KEY  (`user_id`,`property`),
#   CONSTRAINT `user_property` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
