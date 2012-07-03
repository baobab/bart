
class Reports::PreARTReport

  def initialize(start_date, end_date)                                          
    @start_date = "#{start_date.to_date.to_s} 00:00:00"                                      
    @end_date = "#{end_date.to_date.to_s} 23:59:59"
    @cumulative_start = '1900-01-01 00:00:00'
  end 

  def total_registered(start_date = @start_date , end_date = @end_date)
    results = ActiveRecord::Base.connection.select_all <<EOF
SELECT p.* FROM patient p 
INNER JOIN encounter e ON p.patient_id = e.patient_id 
INNER JOIN obs ON e.encounter_id = obs.encounter_id WHERE obs.voided=0 
AND encounter_type = 5 AND e.encounter_datetime >= '#{start_date}' 
AND e.encounter_datetime <= '#{end_date}'
AND e.patient_id NOT IN(
SELECT patient_id FROM patient_registration_dates r 
WHERE r.`registration_date` >= '#{@cumulative_start}' 
AND r.`registration_date` <= '#{end_date}')
GROUP BY e.patient_id
ORDER BY MAX(e.encounter_datetime) DESC
EOF

    results.collect{|p|Patient.find(p['patient_id'])}
  end

  def cumulative_total_registered
    total_registered(@cumulative_start,@end_date)
  end

  def quarterly_total_registered
    total_registered(@start_date,@end_date)
  end

end
