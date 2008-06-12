require "composite_primary_keys"
class RoleRole < OpenMRS
  set_table_name "role_role"
  belongs_to :role, :foreign_key => :role_id
  set_primary_keys :parent_role_id, :child_role_id
end


### Original SQL Definition for role_role #### 
#   `parent_role_id` int(11) NOT NULL ,
#   `child_role_id` int(11) NOT NULL ,
#   PRIMARY KEY  (`parent_role_id`,`child_role_id`),
#   KEY `inherited_role` (`child_role_id`),
#   CONSTRAINT `inherited_role` FOREIGN KEY (`child_role_id`) REFERENCES `role` (`role_id`),
#   CONSTRAINT `parent_role` FOREIGN KEY (`parent_role_id`) REFERENCES `role` (`role_id`)
