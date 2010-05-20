class TableHivRelatedIllness < OpenMRS
  set_table_name "tblHIVRelatedIllness"

  def self.get_all_patient_illness(patient_id = nil)
    self.find(:all,
      :conditions => ["PatientID=?",patient_id]) rescue []
  end

end 
