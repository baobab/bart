# PatientRegimenIngredient collects all of the ingredient concepts for all drugs
# for all orders for a given encounter. The ingredients are associated with 
# ingredients from all known ARV regimens. This information can be used to 
# determine which regimens have had all of their required ingredients dispensed.
#
# You should not need to use this information directly. It is used within the
# <tt>PatientRegimen</tt> model. It is included here as a stub for testing and
# specifications.
class PatientRegimenIngredient < ActiveRecord::Base
  set_table_name :patient_regimen_ingredients
  belongs_to :drug_ingredient
  belongs_to :regimen, :foreign_key => 'regimen_concept_id'
  belongs_to :patient
  belongs_to :encounter
end
=begin
CREATE VIEW patient_regimen_ingredients (ingredient_concept_id, regimen_concept_id, patient_id, encounter_id, dispensed_date) AS
  SELECT 
    regimen_ingredient.ingredient_id as ingredient_concept_id,
    regimen_ingredient.concept_id as regimen_concept_id,
    encounter.patient_id as patient_id, 
    encounter.encounter_id as encounter_id, 
    encounter.encounter_datetime as dispensed_date
  FROM encounter
  INNER JOIN orders ON orders.encounter_id = encounter.encounter_id
  INNER JOIN drug_order ON drug_order.order_id = orders.order_id
  INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
  INNER JOIN drug_ingredient as dispensed_ingredient ON drug.concept_id = dispensed_ingredient.concept_id
  INNER JOIN drug_ingredient as regimen_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id 
  INNER JOIN concept as regimen_concept ON regimen_ingredient.concept_id = regimen_concept.concept_id 
  WHERE encounter.encounter_type = 3 AND regimen_concept.class_id = 18 AND orders.voided = 0
  GROUP BY encounter.encounter_id, regimen_ingredient.concept_id, regimen_ingredient.ingredient_id;
=end