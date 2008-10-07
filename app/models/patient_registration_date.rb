# PatientRegistrationDate is a view which allows you to quickly get a list of every 
# patient registration date in the system. The query is optimized such that calling 
# this query repeatedly should not impact performance. The calculation is based 
# on first line regimen dispensations. PatientRegistrationDate does not use the 
# 'Date of ART initiation' observations so if you want to include those 
# observations, use PatientStartDate instead.
#
# = See also
# <tt>PatientFirstLineRegimenDispensation</tt> 
# <tt>PatientDispensationAndInitiationDate</tt>  
class PatientRegistrationDate < ActiveRecord::Base
  set_table_name :patient_registration_dates
  set_primary_key :patient_id
  belongs_to :patient
  belongs_to :location
end
=begin
CREATE VIEW patient_registration_dates (patient_id, location_id, registration_date) AS
  SELECT encounter.patient_id, encounter.location_id, MIN(encounter.encounter_datetime)
  FROM encounter
  INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
  INNER JOIN drug_order ON drug_order.order_id = orders.order_id
  INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
  INNER JOIN concept_set as arv_drug_concepts ON arv_drug_concepts.concept_set = 460 AND arv_drug_concepts.concept_id = drug.concept_id  
  WHERE encounter.encounter_type = 3
  GROUP BY patient_id, location_id;
=end