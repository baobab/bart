require "composite_primary_keys"
class ConceptSetDerived < OpenMRS
  set_table_name "concept_set_derived"
  set_primary_keys :concept_id, :concept_set
end


### Original SQL Definition for concept_set_derived #### 
#   `concept_id` int(11) NOT NULL default '0',
#   `concept_set` int(11) NOT NULL default '0',
#   `sort_weight` double default NULL,
#   PRIMARY KEY  (`concept_id`,`concept_set`)
