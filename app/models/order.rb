class Order < OpenMRS
  set_table_name "orders"
  set_primary_key "order_id"
  has_many :observations, :foreign_key => :order_id, :class_name => 'Observation', :dependent => :destroy
  has_many :drug_orders, :foreign_key => :order_id, :dependent => :destroy
  belongs_to :order_type, :foreign_key => :order_type_id
  belongs_to :encounter, :foreign_key => :encounter_id
  belongs_to :user, :foreign_key => :user_id

  def patient
    return self.encounter.patient
  end
end


### Original SQL Definition for orders #### 
#   `order_id` int(11) NOT NULL auto_increment,
#   `order_type_id` int(11) NOT NULL default '0',
#   `concept_id` int(11) NOT NULL default '0',
#   `orderer` int(11) default '0',
#   `encounter_id` int(11) default NULL,
#   `instructions` text,
#   `start_date` datetime default NULL,
#   `auto_expire_date` datetime default NULL,
#   `discontinued` tinyint(1) NOT NULL default '0',
#   `discontinued_date` datetime default NULL,
#   `discontinued_by` int(11) default NULL,
#   `discontinued_reason` varchar(255) default NULL,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `voided` tinyint(1) NOT NULL default '0',
#   `voided_by` int(11) default NULL,
#   `date_voided` datetime default NULL,
#   `void_reason` varchar(255) default NULL,
#   PRIMARY KEY  (`order_id`),
#   KEY `order_creator` (`creator`),
#   KEY `orderer_not_drug` (`orderer`),
#   KEY `orders_in_encounter` (`encounter_id`),
#   KEY `type_of_order` (`order_type_id`),
#   KEY `user_who_discontinued_order` (`discontinued_by`),
#   KEY `user_who_voided_order` (`voided_by`),
#   CONSTRAINT `orderer_not_drug` FOREIGN KEY (`orderer`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `orders_in_encounter` FOREIGN KEY (`encounter_id`) REFERENCES `encounter` (`encounter_id`),
#   CONSTRAINT `order_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `type_of_order` FOREIGN KEY (`order_type_id`) REFERENCES `order_type` (`order_type_id`),
#   CONSTRAINT `user_who_discontinued_order` FOREIGN KEY (`discontinued_by`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_voided_order` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
