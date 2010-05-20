class TableHospitalization < OpenMRS
  set_table_name "tblHospitalizations"

  def self.all_hospital_visit
    self.find(:all,:order => "PatientID")
  end
end 
