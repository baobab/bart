class SchedulerTaskConfig < OpenMRS
  set_table_name "scheduler_task_config"
  has_many :scheduler_task_config_properties, :foreign_key => :task_config_id
  belongs_to :user, :foreign_key => :user_id
#
  set_primary_key ""
end


### Original SQL Definition for scheduler_task_config #### 
#    `task_config_id` int(11) NOT NULL auto_increment,
#    `name` varchar(255) NOT NULL,
#    `description` varchar(1024) DEFAULT NULL,
#    `schedulable_class` text DEFAULT NULL,
#    `start_time` datetime NOT NULL,
#    `start_time_pattern` varchar(50) DEFAULT NULL,  
#    `repeat_interval` int(11) NOT NULL default '0',
#    `start_on_startup` int(1) NOT NULL default '0',
#    `started` int(1) NOT NULL default '0',
#    `created_by` int(11) default '0',
#    `date_created` datetime default '0000-00-00 00:00:00',
#    `changed_by` int(11) default NULL,
#    `date_changed` datetime default NULL,
#    PRIMARY KEY (`task_config_id`),
#    KEY `schedule_creator` (`created_by`),
#    KEY `schedule_changer` (`changed_by`),
#    CONSTRAINT `scheduler_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`),
#    CONSTRAINT `scheduler_changer` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`)
#  
