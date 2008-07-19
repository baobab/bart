require 'digest/sha1'

class User < OpenMRS

  cattr_accessor :current_user

  set_table_name "users"
  validates_presence_of:username,:password, :message =>"Fill in Username"
  validates_length_of:username, :within => 4..20
  validates_uniqueness_of:username
 #validates_length_of:password, :within => 4..50
  
  

  has_many :patient_identifier_types, :foreign_key => :creator
  has_many :order_types, :foreign_key => :creator
  has_many :obs, :foreign_key => :voided_by
  has_many :hl7_sources, :foreign_key => :creator
  has_many :drugs, :foreign_key => :creator
  has_many :concept_sources, :foreign_key => :voided_by
  has_many :concept_classes, :foreign_key => :creator
  has_many :concepts, :foreign_key => :changed_by
  has_many :user_properties, :foreign_key => :user_id
  has_many :form_fields, :foreign_key => :changed_by
  has_many :patient_identifiers, :foreign_key => :voided_by
  has_many :field_answers, :foreign_key => :creator
  has_many :concept_answers, :foreign_key => :creator
  has_many :fields, :foreign_key => :creator
  has_many :concept_synonyms, :foreign_key => :creator
  has_many :concept_sets, :foreign_key => :creator
  has_many :relationship_types, :foreign_key => :creator
  has_many :patient_names, :foreign_key => :voided_by
  has_many :patients, :foreign_key => :voided_by
  has_many :orders, :foreign_key => :voided_by
  has_many :formentry_errors, :foreign_key => :creator
  has_many :scheduler_task_configs, :foreign_key => :changed_by
  has_many :notification_alert_recipients, :foreign_key => :user_id
  has_many :relationships, :foreign_key => :voided_by
  has_many :formentry_archives, :foreign_key => :creator
  has_many :encounter_types, :foreign_key => :creator
  has_many :concept_names, :foreign_key => :creator
  has_many :notes, :foreign_key => :creator
  has_many :notification_alerts, :foreign_key => :changed_by
  has_many :users, :foreign_key => :voided_by
  has_many :patient_addresses, :foreign_key => :voided_by
  has_many :forms, :foreign_key => :retired_by
  has_many :encounters, :foreign_key => :provider_id
  has_many :reports, :foreign_key => :voided_by
  has_many :field_types, :foreign_key => :creator
  has_many :concept_proposals, :foreign_key => :creator
  has_many :concept_maps, :foreign_key => :creator
  has_many :concept_datatypes, :foreign_key => :creator
  has_many :report_objects, :foreign_key => :voided_by
  has_many :user_roles, :foreign_key => :user_id, :dependent => :delete_all
  has_many :roles, :through => :user_roles, :foreign_key => :user_id
  has_many :people, :foreign_key => :user_id
  has_many :locations, :foreign_key => :creator
  belongs_to :user, :foreign_key => :user_id
  
  has_one :activities_property, 
          :class_name => 'UserProperty',
          :foreign_key => :user_id,
          :conditions => ['property = ?', 'Activities']

#user_id
  set_primary_key "user_id"

  def name
    self.first_name + " " + self.last_name
  end
  
  def has_role(name)
    self.roles.each{|role|
      return true if role.role == name
    }
    return false
  end

  def has_privilege_by_name(privilege_name)
    self.has_privilege(Privilege.find_by_privilege(privilege_name))
  end
  
  def has_privilege(privilege)
    raise "has_privilege method expects privilege object not string, use has_privilege_by_name instead" if privilege.class == String
    self.roles.each{|role|
      role.privileges.each{|priv|
        return true if priv == privilege
      }
    }
    return false
  end

  def activities
    a = activities_property
    return [] unless a
    a.property_value.split(',')
  end

  # Should we eventually check that they cannot assign an activity they don't
  # have a corresponding privilege for?
  def activities=(arr)
    prop = activities_property || UserProperty.new    
    prop.property = 'Activities'
    prop.property_value = arr.join(',')
    prop.user_id = self.id
    prop.save
  end  

  def current_programs
    disable_tb_program = GlobalProperty.find_by_property("disable_tb_program")
    current_programs = Array.new
    return current_programs if self.activities == ['General Reception']
    current_programs << Program.find_by_name("HIV")
    current_programs << Program.find_by_name("Tuberculosis (TB)") unless self.activities.grep(/TB/).empty? || (disable_tb_program && disable_tb_program.property_value == "true")
    return current_programs
  end

  def privileges
    self.roles.collect{|role|
      role.privileges
    }.flatten.uniq
  end

  def before_create
    super
    self.salt = User.random_string(10) if !self.salt?
    self.password = User.encrypt(self.password,self.salt) 
  end
  
  def before_update
    super
    self.salt = User.random_string(10) if !self.salt?
    self.password = User.encrypt(self.password,self.salt) 
  end
  
  def self.encrypt(password,salt)
    Digest::SHA1.hexdigest(password+salt)
  end 
   
  def after_create
    super
    @password=nil
  end
  
  def self.authenticate(username,password)
    @user = User.find(:first ,:conditions =>["username=? ", username])
   
    salt=@user.salt unless @user.nil?
    
    return nil if @user.nil?
    return @user if encrypt(password, salt)==@user.password
  end 
  
  def try_to_login
    User.authenticate(self.username,self.password)
  end
  
  
  def self.random_string(len)
    #generat a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end
  
  # Assign the specified role to this user
  def assign_role(role)
    user_role = UserRole.new
    user_role.role_id = role.id
    user_role.user_id = self.id
    user_role.save
  end

end


### Original SQL Definition for users #### 
#   `user_id` int(11) NOT NULL auto_increment,
#   `system_id` varchar(50) NOT NULL default '',
#   `username` varchar(50) default NULL,
#   `first_name` varchar(50) default NULL,
#   `middle_name` varchar(50) default NULL,
#   `last_name` varchar(50) default NULL,
#   `password` varchar(50) default NULL,
#   `salt` varchar(50) default NULL,
#   `secret_question` varchar(255) default NULL,
#   `secret_answer` varchar(255) default NULL,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `changed_by` int(11) default NULL,
#   `date_changed` datetime default NULL,
#   `voided` tinyint(1) NOT NULL default '0',
#   `voided_by` int(11) default NULL,
#   `date_voided` datetime default NULL,
#   `void_reason` varchar(255) default NULL,
#   PRIMARY KEY  (`user_id`),
#   KEY `user_creator` (`creator`),
#   KEY `user_who_changed_user` (`changed_by`),
#   KEY `user_who_voided_user` (`voided_by`),
#   CONSTRAINT `user_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_changed_user` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_voided_user` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
