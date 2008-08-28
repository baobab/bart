# Patient Prescription collects all of the "Prescribed dose" (375) and 
# "Prescription time period" (345)  observations for a given encounter.
# Each observation creates a new row in the view. Attached to the row 
# are the actual number of tablets required for the given time period
# and the daily consumption. This information can be used directly, however
# it should be noted that if you want to work with totals for each drug
# then you should instead use <tt>PatientPrescriptionTotal</tt> which
# aggregates the data.
#
# For more information about frequencies see <tt>PrescriptionFrequency</tt>. For
# more information about time periods see <tt>PrescriptionTimePeriod</tt>.
class PatientPrescription < ActiveRecord::Base
  set_table_name :patient_prescriptions
  belongs_to :patient
  belongs_to :encounter
  belongs_to :drug
end
=begin
CREATE VIEW patient_prescriptions (patient_id, encounter_id, prescription_datetime, drug_id, frequency, dose_amount, time_period, quantity, daily_consumption) AS
  SELECT encounter.patient_id, 
         encounter.encounter_id, 
         prescribed_dose.obs_datetime, 
         prescribed_dose.value_drug,
         prescribed_dose.value_text,
         prescribed_dose.value_numeric,
         prescribed_time_period.value_text,
         (prescribed_dose.value_numeric * (prescription_time_periods.time_period_days / prescription_frequencies.frequency_days)),
         (prescribed_dose.value_numeric / prescription_frequencies.frequency_days)
  FROM encounter
  INNER JOIN obs AS prescribed_dose ON 
    prescribed_dose.concept_id = 375 AND 
    prescribed_dose.encounter_id = encounter.encounter_id AND 
    prescribed_dose.value_drug IS NOT NULL AND 
    prescribed_dose.voided = 0
  INNER JOIN obs AS prescribed_time_period ON 
    prescribed_time_period.concept_id = 345 AND
    prescribed_time_period.encounter_id = encounter.encounter_id AND 
    prescribed_time_period.voided = 0
  INNER JOIN prescription_frequencies ON prescription_frequencies.frequency = prescribed_dose.value_text  
  INNER JOIN prescription_time_periods ON prescription_time_periods.time_period = prescribed_time_period.value_text  
  WHERE encounter.encounter_type = 2;
=end
