require "composite_primary_keys"
class ConceptWord < OpenMRS
  set_table_name "concept_word"
  belongs_to :concept, :foreign_key => :concept_id
  set_primary_keys :concept_id, :word, :synonym, :locale
end


### Original SQL Definition for concept_word #### 
#   `concept_id` int(11) NOT NULL default '0',
#   `word` varchar(50) NOT NULL default '',
#   `synonym` varchar(255) NOT NULL default '',
#   `locale` varchar(20) NOT NULL default '',
#   PRIMARY KEY  (`concept_id`,`word`,`synonym`,`locale`),
#   CONSTRAINT `word_for` FOREIGN KEY (`concept_id`) REFERENCES `concept` (`concept_id`)
