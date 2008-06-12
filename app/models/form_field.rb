class FormField < OpenMRS
  set_table_name "form_field"
  has_many :form_fields, :foreign_key => :parent_form_field
  belongs_to :form_field, :foreign_key => :form_field_id
  belongs_to :field, :foreign_key => :field_id
  belongs_to :user, :foreign_key => :user_id
  belongs_to :form, :foreign_key => :form_id
#form_field_id
  set_primary_key "form_field_id"
end


### Original SQL Definition for form_field #### 
#   `form_field_id` int(11) NOT NULL auto_increment,
#   `form_id` int(11) NOT NULL default '0',
#   `field_id` int(11) NOT NULL default '0',
#   `field_number` int(11) default NULL,
#   `field_part` varchar(5) default NULL,
#   `page_number` int(11) default NULL,
#   `parent_form_field` int(11) default NULL,
#   `min_occurs` int(11) default NULL,
#   `max_occurs` int(11) default NULL,
#   `required` tinyint(1) default NULL,
#   `changed_by` int(11) default NULL,
#   `date_changed` datetime default NULL,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`form_field_id`),
#   KEY `user_who_last_changed_form_field` (`changed_by`),
#   KEY `field_within_form` (`field_id`),
#   KEY `form_containing_field` (`form_id`),
#   KEY `form_field_hierarchy` (`parent_form_field`),
#   KEY `user_who_created_form_field` (`creator`),
#   CONSTRAINT `field_within_form` FOREIGN KEY (`field_id`) REFERENCES `field` (`field_id`),
#   CONSTRAINT `form_containing_field` FOREIGN KEY (`form_id`) REFERENCES `form` (`form_id`),
#   CONSTRAINT `form_field_hierarchy` FOREIGN KEY (`parent_form_field`) REFERENCES `form_field` (`form_field_id`),
#   CONSTRAINT `user_who_created_form_field` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_last_changed_form_field` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`)
