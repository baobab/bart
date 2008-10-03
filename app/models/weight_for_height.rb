class WeightForHeight < ActiveRecord::Base
  set_table_name :weight_for_heights

  def self.patient_weight_for_height_values
    # corrected_height = self.significant(patient_height) #correct height to the neares .5
    height_for_weight = Hash.new
    self.find(:all).each{|hwt|
      height_for_weight[hwt.supine_cm] = hwt.median_weight_height
    }   
    return height_for_weight.to_json  
  end

 
  def self.significant(patient_height)
    strip_point         = patient_height.to_s.length - 1
    decimal_digit       = patient_height.to_s.strip[strip_point..strip_point]
    siginificant_height = patient_height.round
    siginificant_height = patient_height.round - 0.5 if decimal_digit.to_i >= 5
    return siginificant_height
  end	

end