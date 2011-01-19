# PatientDispensationAndInitiationDate is a simple view that combines all of 
# first ARV dispensation dates with all of the 'Date of ART Initiation'
# observations. The first date in the list for each patient is the patient's
# start date. If you are trying to get the patient's starting date, use the
# <tt>PatientStartDate</tt> model instead as it automatically groups and chooses
# The earliest date for you.
class PatientDispensationAndInitiationDate < ActiveRecord::Base
  set_table_name :patient_dispensations_and_initiation_dates
  belongs_to :patient
end

=begin
-- 143 = Concept "Date of ART initiation"
DROP VIEW IF EXISTS patient_dispensations_and_initiation_dates;
CREATE VIEW patient_dispensations_and_initiation_dates (
              patient_id, start_date) AS
  SELECT encounter.patient_id,
         MIN(encounter.encounter_datetime) AS start_date
    FROM encounter
    INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND
                         orders.voided = 0
    INNER JOIN drug_order ON drug_order.order_id = orders.order_id
    INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
    INNER JOIN concept_set as arv_drug_concepts ON
               arv_drug_concepts.concept_set = 460 AND
               arv_drug_concepts.concept_id = drug.concept_id
    WHERE encounter.encounter_type = 3
    GROUP BY patient_id
  UNION SELECT patient_id, value_datetime AS start_date
    FROM obs
    WHERE concept_id = 143;
=end