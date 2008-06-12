class ConceptAnswer < OpenMRS
  set_table_name "concept_answer"
  set_primary_key "concept_answer_id"
  set_fixture_name "concept.name", "answer_option.name"
  
  belongs_to :concept, :foreign_key => :concept_id
  belongs_to :answer_option, :class_name => "Concept", :foreign_key => :answer_concept
  belongs_to :user, :foreign_key => :user_id

  validates_uniqueness_of :answer_concept, :scope => "concept_id"  
end