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
      #FasterCSV.read(RAILS_ROOT + "/app/models/all_drug_order_combinations.csv").each do |line|
      (DrugOrderCombination.find(:all) || []).each do | combination |
        regimen = DrugOrderCombinationRegimen.find_by_drug_order_combination_regimen_id(combination.drug_order_combination_regimen_id).name
        min_weight = combination.min_weight
        max_weight = combination.max_weight
        drug_name = Drug.find(combination.drug_id).name
        frequency = combination.frequency
        dose = combination.units

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
