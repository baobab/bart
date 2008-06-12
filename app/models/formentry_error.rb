class FormentryError < OpenMRS
  set_table_name "formentry_error"
  belongs_to :user, :foreign_key => :user_id
#formentry_error_id
  set_primary_key "formentry_error_id"
end


### Original SQL Definition for formentry_error #### 
#   `formentry_error_id` int(11) NOT NULL auto_increment,
#   `form_data` mediumtext NOT NULL,
#   `error` varchar(255) NOT NULL default '',
#   `error_details` text,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`formentry_error_id`),
#   KEY `User who created formentry_error` (`creator`),
#   CONSTRAINT `User who created formentry_error` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
