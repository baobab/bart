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
  set_table_name :patient_arv_drug_regimen_dispensations
  belongs_to :patient
  belongs_to :encounter
end

=begin
  # Count all of the patients whose first 460 concept_set(Arv Drug) regimen disensation happened in the specified period
DROP VIEW IF EXISTS patient_arv_drug_regimen_dispensations;
DROP TABLE IF EXISTS patient_arv_drug_regimen_dispensations;
CREATE VIEW patient_arv_drug_regimen_dispensations (patient_id, encounter_id, dispensed_date) AS
  SELECT encounter.patient_id, encounter.encounter_id, encounter.encounter_datetime,
  FROM encounter
    INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
    INNER JOIN drug_order ON drug_order.order_id = orders.order_id 
    INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
    INNER JOIN concept_set as arv_drug_concepts ON
      arv_drug_concepts.concept_set = 460 AND
      arv_drug_concepts.concept_id = drug.concept_id;
=end
