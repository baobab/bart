class TableOutcome < OpenMRS
  set_table_name "tblFUSummaries"

  def self.all_outcomes(patient_id=nil)
    outcomes = self.find(:all,
        :conditions => ["EventType='OTH' AND 
        (summary like '%DIED%' OR summary like '%TRANSFERRED OUT%' OR summary like '%STOPPED%') 
        AND PatientID=?",patient_id])
    return if outcomes.blank?
    all_outcomes = []
    outcomes.each do |outcome|
      all_outcomes << "Outcome date:#{outcome.EventDate.to_date rescue nil},Outcome:#{outcome.Summary.split(':')[0] rescue nil},Reason:#{outcome.Summary.split(':')[1] rescue nil}"
    end
    all_outcomes
  end

end 
