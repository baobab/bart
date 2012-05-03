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
require 'fastercsv'

class PatientStartDate < ActiveRecord::Base
  set_table_name :patient_start_dates
  set_primary_key :patient_id
  belongs_to :patient
  has_many :observations, :foreign_key => 'patient_id'

  def self.reset
ActiveRecord::Base.connection.execute <<EOF
    TRUNCATE patient_start_dates;
EOF
#    patient_filter = ''
#    if Location.current_arv_code == 'LLH'
#        patient_filter = "INNER JOIN encounter e ON e.patient_id = patient_dispensations_and_initiation_dates.patient_id AND encounter_datetime >= '2004-07-01' AND encounter_type = 3"
#    end
=begin
ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_start_dates (patient_id, start_date, age_at_initiation)
  SELECT 
    patient_dispensations_and_initiation_dates.patient_id, 
    MIN(start_date) AS start_date, 
    (YEAR(start_date) - YEAR(birthdate)) + IF(((MONTH(start_date) - MONTH(birthdate)) + IF((DAY(start_date) - DAY(birthdate)) < 0, -1, 0)) < 0, -1, 0) +
    (IF((birthdate_estimated = 1 AND MONTH(birthdate) = 7 AND DAY(birthdate) = 1 AND MONTH(start_date) < MONTH(birthdate)), 1, 0)) AS age_at_initiation 
  FROM patient_dispensations_and_initiation_dates
  INNER JOIN patient ON patient.patient_id = patient_dispensations_and_initiation_dates.patient_id
  GROUP BY patient_dispensations_and_initiation_dates.patient_id;
EOF
=end

ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_start_dates (patient_id, start_date, age_at_initiation)
  SELECT 
    patient_dispensations_and_initiation_dates.patient_id, 
    MIN(start_date) AS start_date, 
    age(patient.birthdate,DATE(MIN(start_date)),DATE(patient.date_created),patient.birthdate_estimated) AS age_at_initiation 
  FROM patient_dispensations_and_initiation_dates
  INNER JOIN patient ON patient.patient_id = patient_dispensations_and_initiation_dates.patient_id
  GROUP BY patient_dispensations_and_initiation_dates.patient_id;
EOF



    if Location.current_arv_code == 'LLH'
=begin
      excluded_patients = Patient.find_by_sql("SELECT p.patient_id FROM patient_start_dates p
        WHERE start_date < '2004-07-01' AND NOT EXISTS (
          SELECT e.patient_id FROM encounter e
          INNER JOIN orders o ON o.encounter_id = e.encounter_id AND o.voided = 0
          WHERE p.patient_id = e.patient_id AND encounter_type = 3 AND e.encounter_datetime >= '2004-07-01'
        )").map(&:patient_id)
=end
#      csv_path = RAILS_ROOT + '/db/data/llh/non_cohort_patients.csv'
#      excluded_patients = FasterCSV.read(csv_path).flatten.map(&:to_i)
#      PatientStartDate.delete_all(['patient_id IN (?)', excluded_patients])
   
      # Q2 2009 method
      csv_path = RAILS_ROOT + '/db/data/llh/Q2_2009_patients.csv'
      q2_patients = FasterCSV.read(csv_path).flatten.map(&:to_i)
      new_patients = PatientRegistrationDate.find(:all,
                                                :conditions => ['registration_date >= ?',
                                                                '2009-07-01']).map(&:patient_id)
      PatientStartDate.delete_all(['patient_id NOT IN (?)', q2_patients + new_patients])
    end
  end
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
