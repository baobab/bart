# PatientFirstLineRegimenDispensation is a view which allows you to quickly 
# get a list of every dispensation of the first line regimen in the system. 
# The query is optimized such that calling this query repeatedly should not
# impact performance. If you are trying to determine a patient's start date, 
# however, you should not use this model as it does not include starting dates
# which are based on 'Date of ART initiation' observations. These dates are 
# critical when determining migrated data and patients which have transferred 
# in. Instead use the <tt>PatientStartDate</tt> model (which is based on the
# <tt>PatientDispensationAndInitiationDate</tt> model).
class PatientFirstLineRegimenDispensation < ActiveRecord::Base
  set_table_name :patient_first_line_regimen_dispensations
  belongs_to :patient
  belongs_to :encounter
end

=begin
-- Count all of the patients whose first 450 regimen disensation happened in the specified period
DROP VIEW IF EXISTS patient_first_line_regimen_dispensations;
CREATE VIEW patient_first_line_regimen_dispensations (patient_id, encounter_id, dispensed_date) AS
  SELECT encounter.patient_id, encounter.encounter_id, encounter.encounter_datetime
  FROM encounter 
  WHERE encounter.encounter_type = 3 AND NOT EXISTS (
    SELECT * FROM orders 
    INNER JOIN drug_order ON drug_order.order_id = orders.order_id
    INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
    INNER JOIN drug_ingredient as dispensed_ingredient ON drug.concept_id = dispensed_ingredient.concept_id
    LEFT JOIN drug_ingredient as regimen_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id AND regimen_ingredient.concept_id IN (450)
    WHERE orders.encounter_id = encounter.encounter_id AND dispensed_ingredient.concept_id IS NULL
    GROUP BY encounter.encounter_id, regimen_ingredient.ingredient_id);
=end