require "composite_primary_keys"
class UserRole < OpenMRS
  set_table_name "user_role"
  belongs_to :role, :foreign_key => :role_id
  belongs_to :user, :foreign_key => :user_id
  set_primary_keys :role_id, :user_id
end


### Original SQL Definition for user_role #### 
#   `user_id` int(11) NOT NULL default '0',
#   `role_id` Int(11) NOT NULL ,
#   PRIMARY KEY  (`role_id`,`user_id`),
#   KEY `user_role` (`user_id`),
#   CONSTRAINT `role_definitions` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`),
#   CONSTRAINT `user_role` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
