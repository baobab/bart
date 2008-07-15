class Role < OpenMRS
  set_table_name "role"
  has_many :role_roles, :foreign_key => :parent_role_id
  has_many :role_privileges, :foreign_key => :role_id, :dependent => :delete_all
  has_many :privileges, :through => :role_privileges, :foreign_key => :role_id
  has_many :user_roles, :foreign_key => :role_id
#role_id
  set_primary_key "role_id"

end


### Original SQL Definition for role #### 
#   `role_id` int(11) NOT NULL auto_increment,
#   `role` varchar(50) NOT NULL default '',
#   `description` varchar(255) NOT NULL default '',
#   PRIMARY KEY  (`role_id`)
