class PatientIdentifierType < OpenMRS
  set_table_name "patient_identifier_type"
  has_many :patient_identifiers, :foreign_key => :identifier_type
  belongs_to :user, :foreign_key => :user_id
#patient_identifier_type_id
  set_primary_key "patient_identifier_type_id"
  
  @@patient_identifier_hash_by_name = Hash.new
  self.find(:all).each{|patient_identifier|
    @@patient_identifier_hash_by_name[patient_identifier.name.downcase] = patient_identifier
  }

# Use the cache hash to get these fast
  def self.find_by_name(patient_identifier_name)
    return @@patient_identifier_hash_by_name[patient_identifier_name.downcase] || super
  end
  
end


### Original SQL Definition for patient_identifier_type #### 
#   `patient_identifier_type_id` int(11) NOT NULL auto_increment,
#   `name` varchar(50) NOT NULL default '',
#   `description` text NOT NULL,
#   `format` varchar(50) default NULL,
#   `check_digit` tinyint(1) NOT NULL default '0',
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`patient_identifier_type_id`),
#   KEY `type_creator` (`creator`),
#   CONSTRAINT `type_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
