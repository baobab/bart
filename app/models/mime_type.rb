class MimeType < OpenMRS
  set_table_name "mime_type"
  has_many :complex_obs, :foreign_key => :mime_type_id
#mime_type_id
  set_primary_key "mime_type_id"
end


### Original SQL Definition for mime_type #### 
#   `mime_type_id` int(11) NOT NULL auto_increment,
#   `mime_type` varchar(75) NOT NULL default '',
#   `description` text,
#   PRIMARY KEY  (`mime_type_id`),
#   KEY `mime_type_id` (`mime_type_id`)
