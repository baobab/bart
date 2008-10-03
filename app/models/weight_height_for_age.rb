class WeightHeightForAge < ActiveRecord::Base
set_table_name :weight_height_for_ages

 def self.patient_height_weight_values(patient)
  return self.find(:all, :conditions =>["age_in_months =? and sex = ?", patient.age_in_months,(patient.gender == "Female"?0:1)]).first	
 end

 def self.median_weight(patient)
  weight_values = self.patient_height_weight_values(patient)
  return weight_values.median_weight unless weight_values.blank?	 
 end	 

 def self.median_height(patient)
  weight_values = self.patient_height_weight_values(patient)
  return weight_values.median_height unless weight_values.blank?	 
 end	 

end
