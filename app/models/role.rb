class Role < OpenMRS
  set_table_name "role"
  has_many :role_roles, :foreign_key => :parent_role_id
  has_many :role_privileges, :foreign_key => :role_id, :dependent => :delete_all
  has_many :privileges, :through => :role_privileges, :foreign_key => :role_id
  has_many :user_roles, :foreign_key => :role_id
#role_id
  set_primary_key "role_id"

  def self.setup_privileges_for_roles
#    roles = ["provider", "superuser", "Clinician", "Nurse", "Pharmacist", "Registration Clerk", "Vitals Clerk", "Therapeutic Feeding Clerk"]
#    privileges = ["HIV First visit", "ART Visit", "Give drugs", "ART Transfer in", "HIV Staging", "HIV Reception", "Height/Weight", "Barcode scan", "Update outcome"]

    Role.find(:all).each{|r|
      Privilege.find(:all).each{|p|
        self.add_privilege(p)
      }
    }
    
  end

  def add_privilege(privilege)
    rp = RolePrivilege.new
    rp.role_id = self.id
    rp.privilege_id = privilege.id
    rp.save
  end


end


### Original SQL Definition for role #### 
#   `role_id` int(11) NOT NULL auto_increment,
#   `role` varchar(50) NOT NULL default '',
#   `description` varchar(255) NOT NULL default '',
#   PRIMARY KEY  (`role_id`)
