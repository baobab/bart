class OrderType < OpenMRS
  set_table_name "order_type"
  has_many :orders, :foreign_key => :order_type_id
  belongs_to :user, :foreign_key => :user_id
#order_type_id
  set_primary_key "order_type_id"

  @@encounter_type_hash_by_name = Hash.new
  self.find(:all).each{|encounter_type|
    @@encounter_type_hash_by_name[encounter_type.name.downcase] = encounter_type
  }

  def self.find_by_name(encounter_type_name)
    return @@encounter_type_hash_by_name[encounter_type_name.downcase] || super
  end
end


### Original SQL Definition for order_type #### 
#   `order_type_id` int(11) NOT NULL auto_increment,
#   `name` varchar(255) NOT NULL default '',
#   `description` varchar(255) NOT NULL default '',
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`order_type_id`),
#   KEY `type_created_by` (`creator`),
#   CONSTRAINT `type_created_by` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
