class SchedulerTaskConfigProperty < OpenMRS
  set_table_name "scheduler_task_config_property"
  belongs_to :scheduler_task_config, :foreign_key => :task_config_id
#
  set_primary_key ""
end


### Original SQL Definition for scheduler_task_config_property #### 
#     `task_config_id` int(11) NOT NULL default '0',
#     `property` varchar(100) NOT NULL default '',
#     `property_value` varchar(255) NOT NULL default '',
#     PRIMARY KEY (`task_config_id`, `property`),
#     CONSTRAINT `task_config_property` FOREIGN KEY (`task_config_id`) REFERENCES `scheduler_task_config` (`task_config_id`)
#  
