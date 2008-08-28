# PatientDefaultDate allows you to look up every date that a patient has
# actually defaulted. Defaulting, in the electronic system, is defined as 
# failing to receive drugs within two months from the date the last drugs
# run out. 
# 
# A patient may have multiple default dates, where they have defaulted and
# restarted treatment. Additionally, it is possible that a patient who has
# silently transfered out may appear as a defaulter and then at a later 
# point in time reappear. In such a case retrospective outcome observations
# will eliminate the defaulter status.
#
# A patient with a default date is not necessarily a defaulter at present.
# In order to determine the current outcome you must look at the most 
# recent outcome from the PatientOutcome model.
#
# If the patient receives ARV drugs or has an outcome observation within
# the specified time period then they are not considered a defaulter. If 
# the patient has said that they will not continue art treatment or that 
# they will not continue treatment at the current clinic then they are not
# considered a defaulter.
#
# The date that drugs run out and the potential date of default are determined
# by looking in the PatientAdherenceDate table. 
#
# TODO: This view relies on indexed/warehoused tables. It should probably 
# TODO: preload these tables when it is accessed to ensure they are current
#
class PatientDefaultDate < ActiveRecord::Base
  set_table_name :patient_default_dates
  belongs_to :patient
end

=begin
CREATE VIEW patient_default_dates (patient_id, default_date) AS
  SELECT patient_id, default_date 
  FROM patient_adherence_dates 
  WHERE
  NOT EXISTS (SELECT * FROM obs 
              WHERE obs.concept_id = 28 AND
                    obs.patient_id = patient_adherence_dates.patient_id AND
                    obs.obs_datetime >= patient_adherence_dates.visit_date AND 
                    obs.obs_datetime <= patient_adherence_dates.default_date) AND
  NOT EXISTS (SELECT * FROM obs 
              WHERE obs.value_coded <> 3 AND
                    (obs.concept_id = 372 OR obs.concept_id = 367) AND
                    obs.patient_id = patient_adherence_dates.patient_id AND
                    obs.obs_datetime >= patient_adherence_dates.visit_date AND 
                    obs.obs_datetime <= patient_adherence_dates.default_date) AND
  NOT EXISTS (SELECT * FROM encounter
              INNER JOIN orders ON orders.encounter_id = encounter.encounter_id
              INNER JOIN drug_order ON drug_order.order_id = orders.order_id
              INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
              INNER JOIN concept_set as arv_drug_concepts ON arv_drug_concepts.concept_set = 460 AND arv_drug_concepts.concept_id = drug.concept_id  
              WHERE encounter.encounter_type = 3 AND
                    encounter.patient_id = patient_adherence_dates.patient_id AND
                    encounter.encounter_datetime > patient_adherence_dates.visit_date AND
                    encounter.encounter_datetime <= patient_adherence_dates.default_date);
=end