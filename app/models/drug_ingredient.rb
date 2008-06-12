require "composite_primary_keys"
class DrugIngredient < OpenMRS
  set_table_name "drug_ingredient"
  belongs_to :concept, :foreign_key => :concept_id
  belongs_to :ingredient, :foreign_key => :ingredient_id, :class_name => 'Concept'
  set_primary_keys :ingredient_id, :concept_id

  def to_fixture_name
    "#{concept.to_fixture_name}_contains_#{ingredient.to_fixture_name}"
  end
end


### Original SQL Definition for drug_ingredient #### 
#   `concept_id` int(11) NOT NULL default '0',
#   `ingredient_id` int(11) NOT NULL default '0',
#   PRIMARY KEY  (`ingredient_id`,`concept_id`),
#   KEY `combination_drug` (`concept_id`),
#   CONSTRAINT `combination_drug` FOREIGN KEY (`concept_id`) REFERENCES `concept` (`concept_id`),
#   CONSTRAINT `ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `concept` (`concept_id`)
