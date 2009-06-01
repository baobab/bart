require File.dirname(__FILE__) + '/../spec_helper'

describe Regimen do

  it "should be valid" do
    #regimen = create_sample(Regimen)
    (regimen_name, min_weight, max_weight, drug, frequency, units) = ['Stavudine Lamivudine', 0, 9, 'Stavudine Lamivudine', 'Morning', 1]
    regimen = Regimen.new(regimen_name, min_weight, max_weight, drug, frequency, units)
    regimen.regimen.should == regimen_name
    regimen.min_weight.should == min_weight
    regimen.max_weight.should == max_weight
    regimen.drug.should == drug
    regimen.frequency.should == frequency
    regimen.units.should == units
  end

  it "should list all combinations" do
    combination = Regimen.all_combinations.first
    combination.drug.should == "Stavudine 6 Lamivudine 30 Nevirapine 50"
    combination.regimen.should == "Stavudine Lamivudine Nevirapine (Triomune Baby)" 
    combination.min_weight.should == 3
    combination.max_weight.should == 6
    combination.units.should == 1.0
    combination.frequency.should == "Morning"
  end

  it "should create a drug order" do
    (regimen_name, min_weight, max_weight, drug, frequency, units) = ['Stavudine Lamivudine', 0, 9, 'Stavudine Lamivudine', 'Morning', 1]
    regimen = Regimen.new(regimen_name, min_weight, max_weight, drug, frequency, units)
    drug_order = regimen.to_drug_order
    drug_order.class.should == DrugOrder
    drug_order.order_id.should == 0
    drug_order.drug_inventory_id.should == nil
    drug_order.dose.should be_nil
    drug_order.units.should == 1
    drug_order.frequency.should == "Morning"
    drug_order.prn.should be_false
    drug_order.complex.should be_false
    drug_order.quantity.should be_nil
  end

end
