# PatientStartDate is a view which allows you to quickly get a list of every 
# patient start date in the system. The query is optimized such that calling 
# this query repeatedly should not impact performance. The calculation is based 
# on first line regimen dispensations and 'Date of ART initiation' observations. 
# These dates are critical when determining migrated data and patients which 
# have transferred in. PatientRegistrationDate does not use the 'Date of ART
# initiation' observations so if you want to omit those observations, use
# PatientRegistrationDate instead.
#
# = See also
# <tt>PatientFirstLineRegimenDispensation</tt> 
# <tt>PatientDispensationAndInitiationDate</tt> 
class PatientStartDate < ActiveRecord::Base
  set_table_name :patient_start_dates
  set_primary_key :patient_id
  belongs_to :patient
  has_many :observations, :foreign_key => 'patient_id'
end
=begin
CREATE VIEW patient_start_dates (patient_id, start_date, age_at_initiation) AS
  SELECT 
    patient_dispensations_and_initiation_dates.patient_id, 
    MIN(start_date) AS start_date, 
    (YEAR(start_date) - YEAR(birthdate)) + IF(((MONTH(start_date) - MONTH(birthdate)) + IF((DAY(start_date) - DAY(birthdate)) < 0, -1, 0)) < 0, -1, 0) +
    (IF((birthdate_estimated = 1 AND MONTH(birthdate) = 7 AND DAY(birthdate) = 1 AND MONTH(start_date) < MONTH(birthdate)), 1, 0)) AS age_at_initiation 
  FROM patient_dispensations_and_initiation_dates
  INNER JOIN patient ON patient.patient_id = patient_dispensations_and_initiation_dates.patient_id
  GROUP BY patient_dispensations_and_initiation_dates.patient_id;
=end