class Note < OpenMRS
  set_table_name "note"
  has_many :notes, :foreign_key => :parent
  belongs_to :ob, :foreign_key => :obs_id
  belongs_to :patient, :foreign_key => :patient_id
  belongs_to :note, :foreign_key => :note_id
  belongs_to :user, :foreign_key => :user_id
  belongs_to :encounter, :foreign_key => :encounter_id
#note_id
  set_primary_key "note_id"
end


### Original SQL Definition for note #### 
#   `note_id` int(11) NOT NULL default '0',
#   `note_type` varchar(50) default NULL,
#   `patient_id` int(11) default NULL,
#   `obs_id` int(11) default NULL,
#   `encounter_id` int(11) default NULL,
#   `text` text NOT NULL,
#   `priority` int(11) default NULL,
#   `parent` int(11) default NULL,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `changed_by` int(11) default NULL,
#   `date_changed` datetime default NULL,
#   PRIMARY KEY  (`note_id`),
#   KEY `patient_note` (`patient_id`),
#   KEY `obs_note` (`obs_id`),
#   KEY `encounter_note` (`encounter_id`),
#   KEY `user_who_created_note` (`creator`),
#   KEY `user_who_changed_note` (`changed_by`),
#   KEY `note_hierarchy` (`parent`),
#   CONSTRAINT `encounter_note` FOREIGN KEY (`encounter_id`) REFERENCES `encounter` (`encounter_id`),
#   CONSTRAINT `note_hierarchy` FOREIGN KEY (`parent`) REFERENCES `note` (`note_id`),
#   CONSTRAINT `obs_note` FOREIGN KEY (`obs_id`) REFERENCES `obs` (`obs_id`),
#   CONSTRAINT `patient_note` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`),
#   CONSTRAINT `user_who_changed_note` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_created_note` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
