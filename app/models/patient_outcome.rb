# PatientOutcome lists all of the historical outcomes for a patient. Any time
# the outcome status is affected (either through a new outcome observation, a 
# new dispensation or lack of a dispensation). The possible outcomes are:
#
# <tt>On ART</tt> (Concept: 324)
# <tt>Transfer out</tt> (Concept: 325)
# <tt>Transfer Out(With Transfer Note)</tt> (Concept: 374)
# <tt>Transfer Out(Without Transfer Note)</tt> (Concept: 383)
# <tt>ART Stop</tt> (Concept: 386)
# <tt>Defaulter</tt> (Concept: 373)
# <tt>Died</tt> (Concept: 322)
#
# A patient should have multiple outcome dates. For example a patient with a 
# outcome status of Defaulter is not necessarily a defaulter at present.
# In order to determine the current outcome you must look at the most 
# recent outcome for each patient.
#
# There are several observations that can establish a patient outcome:
#
# <tt>Outcome</tt> (Concept: 28)
# <tt>Continue treatment at current clinic</tt> (Concept: 372)
# <tt>Continue ART</tt> (Concept: 367)
#
# Additionally a patient may have a death date but not have a specific outcome
# observation (Died). Because of this, the patient death date creates a patient
# outcome. 
#
# It is possible to have multiple outcomes (even on a single date), some of 
# which may be duplicates. For example if a patient has an Outcome observation
# with the value Died and the patient has a death date on the same day, there 
# will be two <tt>PatientOutcome</tt> entries with the status Died.
class PatientOutcome < ActiveRecord::Base
  set_table_name :patient_outcomes
  belongs_to :patient
end
=begin
CREATE VIEW patient_outcomes (patient_id, outcome_date, outcome_concept_id) AS
  SELECT encounter.patient_id, encounter.encounter_datetime, 324
  FROM encounter
  INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
  INNER JOIN drug_order ON drug_order.order_id = orders.order_id 
  INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
  INNER JOIN concept_set as arv_drug_concepts ON
    arv_drug_concepts.concept_set = 460 AND
    arv_drug_concepts.concept_id = drug.concept_id
  UNION
  SELECT obs.patient_id, obs.obs_datetime, obs.value_coded 
  FROM obs 
  WHERE obs.concept_id = 28
  UNION
  SELECT obs.patient_id, obs.obs_datetime, 325 
  FROM obs 
  WHERE obs.concept_id = 372 AND obs.value_coded <> 3
  UNION
  SELECT obs.patient_id, obs.obs_datetime, 386 
  FROM obs 
  WHERE obs.concept_id = 367 AND obs.value_coded <> 3
  UNION
  SELECT patient_default_dates.patient_id, patient_default_dates.default_date, 373
  FROM patient_default_dates
  UNION
  SELECT patient.patient_id, patient.death_date, 322
  FROM patient
  WHERE patient.death_date IS NOT NULL;
=end
