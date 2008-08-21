# PatientRegimen allows you to quickly look up every regimen dispensation 
# for a given patient. It does this by determining if all of the regimen
# specific ingredients have been 'satisfied' by the ingredients that were
# actually dispensed. For example if a patient is given Stavudine, Lamivudine,
# and Nevirapine then they will have been given all of the ingredients that
# are contained in the first line regimen. 
#
# A patient may be given additional ingredients (for example, CPT) and are still
# considered to be on the regimen. It is possible (though not likely) for a
# patient to be on two regimens at the same time given the algorithm.
#
# Drug dosages (Stavudine 40 versus Stavudine 30) are ignored.
#
# If a patient is given drugs but the drugs are not part of a defined regimen
# then there will be no <tt>PatientRegimen<tt> entry for that dispensation.
#
# If you are trying to determine the date of a first line regimen dispensation
# only, you should instead use <tt>PatientFirstLineRegimenDispensation</tt> as
# it is much faster.
class PatientRegimen < ActiveRecord::Base
  set_table_name :patient_regimens
  belongs_to :patient
  belongs_to :concept, :foreign_key => 'regimen_concept_id'
  belongs_to :encounter
end
=begin
CREATE VIEW patient_regimens (regimen_concept_id, patient_id, encounter_id, dispensed_date) AS
  SELECT patient_regimen_ingredients.regimen_concept_id as regiment_concept_id,
         patient_regimen_ingredients.patient_id as patient_id,
         patient_regimen_ingredients.encounter_id as encounter_id, 
         patient_regimen_ingredients.dispensed_date as dispensed_date        
  FROM patient_regimen_ingredients
  GROUP BY patient_regimen_ingredients.encounter_id, patient_regimen_ingredients.regimen_concept_id
  HAVING count(*) = (SELECT count(*) FROM drug_ingredient WHERE drug_ingredient.concept_id = patient_regimen_ingredients.regimen_concept_id); 
=end
