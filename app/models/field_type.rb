class FieldType < OpenMRS
  set_table_name "field_type"
  has_many :fields, :foreign_key => :field_type
  belongs_to :user, :foreign_key => :user_id
#field_type_id
  set_primary_key "field_type_id"

  @@field_type_hash_by_name = Hash.new
  @@field_type_hash_by_id = Hash.new
  self.find(:all).each{|field_type|
    @@field_type_hash_by_name[field_type.name.downcase] = field_type
    @@field_type_hash_by_id[field_type.id] = field_type
  }

# Use the cache hash to get these fast
  def self.find_from_ids(args, options)
    super if args.length > 1 and return
    return @@field_type_hash_by_id[args.first] || super
  end
  
  def self.find_by_name(field_type_name)
    return @@field_type_hash_by_name[field_type_name.downcase] || super
  end
  
end


### Original SQL Definition for field_type #### 
#   `field_type_id` int(11) NOT NULL auto_increment,
#   `name` varchar(50) default NULL,
#   `description` longtext,
#   `is_set` tinyint(1) NOT NULL default '0',
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`field_type_id`),
#   KEY `user_who_created_field_type` (`creator`),
#   CONSTRAINT `user_who_created_field_type` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
