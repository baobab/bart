class PatientStartDate < ActiveRecord::Base
  set_table_name :patient_start_dates
  belongs_to :patient
end
