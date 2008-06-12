require "composite_primary_keys"
class FieldAnswer < OpenMRS
  set_table_name "field_answer"
  belongs_to :concept, :foreign_key => :concept_id
  belongs_to :field, :foreign_key => :field_id
  belongs_to :user, :foreign_key => :user_id
  set_primary_keys :field_id, :answer_id
end


### Original SQL Definition for field_answer #### 
#   `field_id` int(11) NOT NULL default '0',
#   `answer_id` int(11) NOT NULL default '0',
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`field_id`,`answer_id`),
#   KEY `answers_for_field` (`field_id`),
#   KEY `field_answer_concept` (`answer_id`),
#   KEY `user_who_created_field_answer` (`creator`),
#   CONSTRAINT `answers_for_field` FOREIGN KEY (`field_id`) REFERENCES `field` (`field_id`),
#   CONSTRAINT `field_answer_concept` FOREIGN KEY (`answer_id`) REFERENCES `concept` (`concept_id`),
#   CONSTRAINT `user_who_created_field_answer` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
