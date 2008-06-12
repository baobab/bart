class FormentryArchive < OpenMRS
  set_table_name "formentry_archive"
  belongs_to :user, :foreign_key => :user_id
#formentry_archive_id
  set_primary_key "formentry_archive_id"
end


### Original SQL Definition for formentry_archive #### 
#   `formentry_archive_id` int(11) NOT NULL auto_increment,
#   `form_data` mediumtext NOT NULL,
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `creator` int(11) NOT NULL default '0',
#   PRIMARY KEY  (`formentry_archive_id`),
#   KEY `User who created formentry_archive` (`creator`),
#   CONSTRAINT `User who created formentry_archive` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
