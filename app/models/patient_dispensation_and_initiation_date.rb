# PatientDispensationAndInitiationDate is a simple view that combines all of 
# first line regimen dispensation dates with all of the 'Date of ART Initiation'
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
CREATE VIEW patient_dispensations_and_initiation_dates (patient_id, start_date) AS
   SELECT patient_id, dispensed_date AS start_date 
   FROM patient_first_line_regimen_dispensations
   UNION SELECT patient_id, value_datetime AS start_date
   FROM obs
   WHERE concept_id = 143;
=end