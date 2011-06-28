require 'fastercsv'

class Regimen
  def initialize(regimen, min_weight, max_weight, drug, frequency, units)
    @regimen, @min_weight,  @max_weight, @drug, @frequency, @units = regimen, min_weight, max_weight, drug, frequency, units
  end

  attr_accessor :regimen, :min_weight, :max_weight, :drug, :frequency, :units
  @@all_combinations = Array.new
        
  def self.all_combinations
    if @@all_combinations.blank?
      drug_name = nil
      max_weight = nil
      min_weight = nil
      regimen = nil
      FasterCSV.read(RAILS_ROOT + "/app/models/all_drug_order_combinations.csv").each do |line|
        next if line[0] == 'Regimen'
        regimen = line[0].strip unless line[0].blank?
        min_weight = line[1].strip unless line[1].blank?
        max_weight = line[2].strip unless line[2].blank?
        drug_name = line[3].strip unless line[3].blank?
        frequency = line[4].strip unless line[4].blank?
        dose = line[5].strip unless line[5].blank?

        reg = Regimen.new(regimen,min_weight.to_f,max_weight.to_f,drug_name,frequency,dose.to_f)
        @@all_combinations << reg
      end
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
