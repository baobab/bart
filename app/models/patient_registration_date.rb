class PatientRegistrationDate < ActiveRecord::Base
  set_table_name :patient_registration_dates
  belongs_to :patient
  belongs_to :location
end
