class Person < OpenMRS
  set_table_name "person"
  has_many :relationships, :foreign_key => :person_id, :dependent => :delete_all
  has_many :related_to, :class_name => "Relationship", :foreign_key => :person_id, :dependent => :delete_all
  has_many :related_from, :class_name => "Relationship", :foreign_key => :relative_id, :dependent => :delete_all
  belongs_to :patient, :foreign_key => :patient_id
  belongs_to :user, :foreign_key => :user_id
#person_id
  set_primary_key "person_id"

  def all_relationships
    self.related_to << self.related_from
  end
end


### Original SQL Definition for person #### 
#   `person_id` int(11) NOT NULL auto_increment,
#   `patient_id` int(11) default NULL,
#   `user_id` int(11) default NULL,
#   PRIMARY KEY  (`person_id`),
#   KEY `patients` (`patient_id`),
#   KEY `users` (`user_id`),
#   CONSTRAINT `patients` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`),
#   CONSTRAINT `users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
