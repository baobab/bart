require File.dirname(__FILE__) + '/../spec_helper'

describe DrugOrder do
  fixtures :drug_order
  fixtures :drug_ingredient, :drug
  fixtures :encounter, :encounter_type, :obs, :orders
  fixtures :concept, :concept_set, :concept_class
  fixtures :patient

  sample({
    :order_id => 1,
    :drug_inventory_id => 5,
    :dose => nil, 
    :units => nil,
    :frequency => nil,
    :prn => false,
    :complex => false,
    :quantity => 60,
  })

  it "should be valid" do
    drug_order = create_sample(DrugOrder)
    drug_order.should be_valid
  end
  
  
  it "should display the drug as a string" do
    drug_order = drug_order(:andreas_abacavir)
    drug_order.to_s.should == "Abacavir 300: 30 (ARV: true)"
  end
  
  it "should display the drug order as prescription string" do
    drug_order = create_sample(DrugOrder, :frequency => 'Morning', :units => 0.25, :drug_inventory_id => 5, :quantity => 30)
    drug_order.to_prescription_s.should == "Stavudine 30 Lamivudine 150 Nevirapine 200: 30mg Morning: 0.25"
  end
  
  it "should have an associated encounter" do
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)
    encounter = encounter(:andreas_drugs)
    drug_order.encounter.should == encounter
  end

  it "should have an associated prescription encounter" do
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)    
    prescription_encounter = encounter(:andreas_art_visit)
    drug_order.prescription_encounter.should == prescription_encounter
  end

  it "should use the encounter date as the drug order date" do
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)
    encounter = encounter(:andreas_drugs)
    drug_order.date.should == encounter.encounter_datetime.to_date
  end

  it "should determine if the order is for ARV drugs" do
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)
    drug_order.should be_arv
    drug_order = create_sample(DrugOrder, :drug_inventory_id => 16)
    drug_order.should_not be_arv
  end

  it "should retrieve prescriptions for the drug(s) which is being ordered" do
    prescriptions_strings = ["Stavudine 30 Lamivudine 150 Nevirapine 200 f:Morning d:1.0 t:1 month", "Stavudine 30 Lamivudine 150 Nevirapine 200 f:Evening d:1.0 t:1 month"]
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)    
    prescriptions = drug_order.prescriptions 
    prescriptions.map(&:to_s).should == prescriptions_strings
  end

  it "should calculate quantity remaining from last order" do
    drug_order = drug_order(:andreas_abacavir)  
    drug_order.quantity_remaining_from_last_order.should == 9
  end

  it "should calculate daily consumption" do 
    drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200).daily_consumption.should == 2
    drug_order(:andreas_abacavir).daily_consumption.should == 1
  end

  it "should calculate quantity including amount remaining from last order" do
    drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200).quantity_including_amount_remaining_from_last_order.should == 70
    drug_order(:andreas_abacavir).quantity_including_amount_remaining_from_last_order.should == 39
  end

  it "should calculate recommended ART prescription for weight" do    
    prescriptions = DrugOrder.recommended_art_prescription(11).to_a
    prescriptions.each{|set| set[1].map!(&:to_prescription_s) }
    prescriptions = prescriptions.sort_by{|p| p[0]}    
    prescriptions.should include(["Stavudine Lamivudine Nevirapine", ["Stavudine 30 Lamivudine 150 Nevirapine 200: Morning: 0.5", "Stavudine 30 Lamivudine 150 Nevirapine 200: Evening: 0.25"]])
  end

  it "should calculate recommended ART prescription for Triopaed weight" do
    prescriptions = DrugOrder.recommended_art_prescription(6)
    prescriptions.each{|set| set[1].map!(&:to_prescription_s) }
    prescriptions = prescriptions.sort_by{|p| p[0]}    
    prescriptions.should include(["Stavudine Lamivudine Nevirapine (Triomune Baby)", ["Stavudine 6 Lamivudine 30 Nevirapine 50: Morning: 1.5", "Stavudine 6 Lamivudine 30 Nevirapine 50: Evening: 1.5"]])
    # "Triopaed prescription is not included in prescriptions: " + prescriptions.to_yaml
  end

=begin
  it "should determine the drug regimen from a set of drug orders" do
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200) 
    DrugOrder.drug_orders_to_regimen([drug_order]).should == concept(:arv_first_line_regimen)
  end

  it "should determine the drug regimen from a blank set of drug orders" do
    DrugOrder.drug_orders_to_regimen([]).should be_nil
  end

  it "should determine the drug regimen from a set of drug orders for first line regimen ARVs" do
    # Stavudine Lamivudine, Neviripine
    drug_orders = [create_sample(DrugOrder, :drug_inventory_id => 1), create_sample(DrugOrder, :drug_inventory_id => 9)]
    DrugOrder.drug_orders_to_regimen(drug_orders).should == concept(:arv_first_line_regimen)
    # Stavudine Lamivudine Neviripine, Stavudine Lamivudine
    drug_orders = [create_sample(DrugOrder, :drug_inventory_id => 5), create_sample(DrugOrder, :drug_inventory_id => 1)]
    DrugOrder.drug_orders_to_regimen(drug_orders).should == concept(:arv_first_line_regimen) 
  end
  
  it "should determine the drug regimen from a set of drug orders for alternative first line regimen ARVs" do
    # Zidovudine Lamivudine, Nevirapine
    drug_orders = [create_sample(DrugOrder, :drug_inventory_id => 8), create_sample(DrugOrder, :drug_inventory_id => 9)]
    DrugOrder.drug_orders_to_regimen(drug_orders).should == concept(:arv_first_line_regimen_alternatives) 
    # Stavudine Lamivudine, Efavirenz
    drug_orders = [create_sample(DrugOrder, :drug_inventory_id => 1), create_sample(DrugOrder, :drug_inventory_id => 7)]
    DrugOrder.drug_orders_to_regimen(drug_orders).should == concept(:arv_first_line_regimen_alternatives) 
  end
  
  it "should determine the drug regimen from a set of drug orders for second line regimen ARVs" do
    # Zidovudine Lamivudine, Tenofovir, Lopinavir/Ritonavir
    drug_orders = [create_sample(DrugOrder, :drug_inventory_id => 8), create_sample(DrugOrder, :drug_inventory_id => 14), create_sample(DrugOrder, :drug_inventory_id => 17)]
    DrugOrder.drug_orders_to_regimen(drug_orders).should == concept(:arv_second_line_regimen)
    # Didanosine, Abacavir, Lopinavir/Ritonavir
    drug_orders = [create_sample(DrugOrder, :drug_inventory_id => 13), create_sample(DrugOrder, :drug_inventory_id => 10), create_sample(DrugOrder, :drug_inventory_id => 17)]
    DrugOrder.drug_orders_to_regimen(drug_orders).should == concept(:arv_second_line_regimen) 
  end
  
  it "should determine the drug regimen from a set of drug orders for an unknown regimen" do
    # Zidovudine Lamivudine, Abacavir
    drug_orders = [create_sample(DrugOrder, :drug_inventory_id => 8), create_sample(DrugOrder, :drug_inventory_id => 10)]
    DrugOrder.drug_orders_to_regimen(drug_orders).should be_nil
    # Nevirapine
    drug_orders = [create_sample(DrugOrder, :drug_inventory_id => 9)]
    DrugOrder.drug_orders_to_regimen(drug_orders).should be_nil
  end

  it "should return a nil regimen if the set of drug orders is nil" do
    DrugOrder.drug_orders_to_regimen([nil]).should be_nil
  end
=end

  it "should return the given dosage" do
    drug_orders = [drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)]
    DrugOrder.given_drugs_dosage(drug_orders).should == ["Stavudine 30 Lamivudine 150 Nevirapine 200,Morning,1.0", "Stavudine 30 Lamivudine 150 Nevirapine 200,Evening,1.0"]
  end  
  
  it "should return the amount given last time" do
    patient = patient(:andreas)
    date = "2007-03-05".to_date
    patient.drugs_given_last_time(date).map{|drug,quantity|["#{drug.name} #{quantity}"]}[0].to_s.should == "Stavudine 30 Lamivudine 150 Nevirapine 200 60"
  end  
    
end
