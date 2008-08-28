class PatientRegistrationDate < ActiveRecord::Base
  set_table_name :patient_registration_dates
  set_primary_key :patient_id
  belongs_to :patient
  belongs_to :location
end
