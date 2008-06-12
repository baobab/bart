class Regimen
  def initialize(regimen, min_weight, max_weight, drug, frequency, units)
    @regimen, @min_weight,  @max_weight, @drug, @frequency, @units = regimen, min_weight, max_weight, drug, frequency, units
  end

  attr_accessor :regimen, :min_weight, :max_weight, :drug, :frequency, :units
  @@all_combinations = Array.new
        
  def self.all_combinations
    if @@all_combinations.blank?
      last_regimen = Array.new
      File.open(File.join(RAILS_ROOT, "app/models/all_drug_order_combinations.csv"), File::RDONLY).readlines[1..-1].each{|line|
        data_row = line.chomp.split(",").collect{|text|text.gsub(/"/,"")} # "
        result = last_regimen
        data_row.each_with_index{|data,index| 
          result[index] = data unless data == ""
        }
        reg = Regimen.new(result[0],result[1].to_i,result[2].to_i,result[3],result[4],result[5].to_f)
        @@all_combinations << reg
        last_regimen = result
      }
    end  
    @@all_combinations
  end

  def to_drug_order    
    drug_order = DrugOrder.new()
    drug_order.frequency = self.frequency
    drug_order.drug = Drug.find_by_name(self.drug)
    drug_order.units = self.units
    drug_order
  end

end
