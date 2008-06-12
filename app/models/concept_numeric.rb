class ConceptNumeric < OpenMRS
  set_table_name "concept_numeric"
  belongs_to :concept, :foreign_key => :concept_id
#concept_id
  set_primary_key "concept_id"
end


### Original SQL Definition for concept_numeric #### 
#   `concept_id` int(11) NOT NULL default '0',
#   `hi_absolute` double default NULL,
#   `hi_critical` double default NULL,
#   `hi_normal` double default NULL,
#   `low_absolute` double default NULL,
#   `low_critical` double default NULL,
#   `low_normal` double default NULL,
#   `units` varchar(50) default NULL,
#   `precise` tinyint(1) NOT NULL default '0',
#   PRIMARY KEY  (`concept_id`),
#   CONSTRAINT `numeric_attributes` FOREIGN KEY (`concept_id`) REFERENCES `concept` (`concept_id`)
