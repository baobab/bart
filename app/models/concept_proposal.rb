class ConceptProposal < OpenMRS
  set_table_name "concept_proposal"
  belongs_to :ob, :foreign_key => :obs_id
  belongs_to :concept, :foreign_key => :concept_id
  belongs_to :user, :foreign_key => :user_id
  belongs_to :encounter, :foreign_key => :encounter_id
#concept_proposal_id
  set_primary_key "concept_proposal_id"
end


### Original SQL Definition for concept_proposal #### 
#   `concept_proposal_id` int(11) NOT NULL auto_increment,
#   `concept_id` int(11) default NULL,
#   `encounter_id` int(11) default NULL,
#   `original_text` varchar(255) NOT NULL default '',
#   `final_text` varchar(255) default NULL,
#   `obs_id` int(11) default NULL,
#   `obs_concept_id` int(11) default NULL,
#   `state` varchar(32) NOT NULL default 'UNMAPPED' COMMENT 'Valid values are: UNMAPPED, SYNONYM, CONCEPT, REJECT',
#   `comments` varchar(255) default NULL COMMENT 'Comment from concept admin/mapper',
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `changed_by` int(11) default NULL,
#   `date_changed` datetime default NULL,
#   PRIMARY KEY  (`concept_proposal_id`),
#   KEY `encounter_for_proposal` (`encounter_id`),
#   KEY `concept_for_proposal` (`concept_id`),
#   KEY `user_who_created_proposal` (`creator`),
#   KEY `user_who_changed_proposal` (`changed_by`),
#   KEY `proposal_obs_id` (`obs_id`),
#   KEY `proposal_obs_concept_id` (`obs_concept_id`),
#   CONSTRAINT `concept_for_proposal` FOREIGN KEY (`concept_id`) REFERENCES `concept` (`concept_id`),
#   CONSTRAINT `encounter_for_proposal` FOREIGN KEY (`encounter_id`) REFERENCES `encounter` (`encounter_id`),
#   CONSTRAINT `proposal_obs_concept_id` FOREIGN KEY (`obs_concept_id`) REFERENCES `concept` (`concept_id`),
#   CONSTRAINT `proposal_obs_id` FOREIGN KEY (`obs_id`) REFERENCES `obs` (`obs_id`),
#   CONSTRAINT `user_who_changed_proposal` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_created_proposal` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
