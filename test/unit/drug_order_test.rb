require File.dirname(__FILE__) + '/../test_helper'

class DrugOrderTest < Test::Unit::TestCase
  # You can move this to test_helper.rb
  set_fixture_class :drug_orders => DrugOrder
  fixtures :drug_order, :users, :location 
  fixtures :drug_ingredient, :drug
  fixtures :encounter, :encounter_type, :obs, :orders
  fixtures :concept, :concept_set, :concept_class
  fixtures :patient

  cattr_reader :drug_order_default_values
  @@drug_order_default_values = {
    :drug_order_id => 1,
    :order_id => 1,
    :drug_inventory_id => 1,
    :dose => 1,
    :units => '',
    :frequency => '',
    :prn => false,
    :complex => false,
    :quantity => 10,
  }

  def setup
    super
    User.current_user = users(:registration)
    Location.current_location = location(:martin_preuss_centre)
  end
  
  def teardown
    super
    User.current_user = nil
    Location.current_location = nil
  end

  def test_should_create_record
    drug_order = create
    assert drug_order.valid?, "Drug order was invalid:\n#{drug_order.to_yaml}"
  end
  
  def test_should_display_drug_as_string
    drug_order = drug_order(:andreas_abacavir)
    assert_equal "Abacavir 300: 30 (ARV: true)", drug_order.to_s 
  end
  
  def test_should_display_drug_order_as_prescription_string
    drug_order = create(:frequency => 'Morning', :units => 0.25, :drug_inventory_id => 5, :quantity => 30)
    assert_equal "Stavudine 30 Lamivudine 150 Nevirapine 200: 30mg Morning: 0.25", drug_order.to_prescription_s 
  end
  
  def test_should_refer_to_encounter
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)
    encounter = encounter(:andreas_drugs)
    assert_equal encounter, drug_order.encounter
  end

  def test_should_use_encounter_date_for_drug_order_date
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)
    encounter = encounter(:andreas_drugs)
    assert_equal encounter.encounter_datetime.to_date, drug_order.date
  end

  def test_should_determine_if_order_is_for_arv_drugs
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)
    assert drug_order.arv?    
    drug_order = create(:drug_inventory_id => 16)
    assert !drug_order.arv?  
  end

  def test_should_refer_to_prescription_encounter
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)    
    prescription_encounter = encounter(:andreas_art_visit)
    assert_equal prescription_encounter, drug_order.prescription_encounter
  end

  def test_should_retrieve_prescriptions_for_the_drug_which_is_being_ordered
    prescriptions_strings = ["Stavudine 30 Lamivudine 150 Nevirapine 200 f:Morning d:1.0 t:1 month", "Stavudine 30 Lamivudine 150 Nevirapine 200 f:Evening d:1.0 t:1 month"]
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)    
    prescriptions = drug_order.prescriptions 
    assert_equal prescriptions_strings, prescriptions.map(&:to_s)
  end

  def test_should_calculate_quantity_remaining_from_last_order
    drug_order = drug_order(:andreas_abacavir)  
    assert_equal 9, drug_order.quantity_remaining_from_last_order    
  end

  def test_should_calculate_daily_consumption
    assert_equal 2, drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200).daily_consumption
    assert_equal 1, drug_order(:andreas_abacavir).daily_consumption
  end

  def test_should_calculate_quantity_including_amount_remaining_from_last_order
    assert_equal 70, drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200).quantity_including_amount_remaining_from_last_order
    assert_equal 39, drug_order(:andreas_abacavir).quantity_including_amount_remaining_from_last_order
  end

  def test_should_calculate_recommended_art_prescription_for_weight    
    prescriptions = DrugOrder.recommended_art_prescription(11).to_a
    prescriptions.each{|set| set[1].map!(&:to_prescription_s) }
    prescriptions = prescriptions.sort_by{|p| p[0]}    
    assert prescriptions.include?(["Stavudine Lamivudine Nevirapine", ["Stavudine 30 Lamivudine 150 Nevirapine 200: Morning: 0.5", "Stavudine 30 Lamivudine 150 Nevirapine 200: Evening: 0.25"]])
  end

  def test_should_calculate_recommended_art_prescription_for_triopaed_weight    
    prescriptions = DrugOrder.recommended_art_prescription(6)
    prescriptions.each{|set| set[1].map!(&:to_prescription_s) }
    prescriptions = prescriptions.sort_by{|p| p[0]}    
    assert prescriptions.include?(["Stavudine Lamivudine Nevirapine (Triomune Baby)", ["Stavudine 6 Lamivudine 30 Nevirapine 50: Morning: 1.5", "Stavudine 6 Lamivudine 30 Nevirapine 50: Evening: 1.5"]]), "Triopaed prescription is not included in prescriptions: " + prescriptions.to_yaml
  end

  def test_should_determine_drug_regimen_from_drug_orders
    drug_order = drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200) 
    assert_equal concept(:arv_first_line_regimen128), DrugOrder.drug_orders_to_regimen([drug_order])
  end

  def test_should_not_determine_drug_regimen_from_blank_drug_orders
    assert_equal nil, DrugOrder.drug_orders_to_regimen([])
  end

  def test_should_determine_drug_regimen_from_drug_orders_for_arv_first_line_regimen
    # Stavudine Lamivudine, Neviripine
    drug_orders = [create(:drug_inventory_id => 1), create(:drug_inventory_id => 9)]
    assert_equal concept(:arv_first_line_regimen128), DrugOrder.drug_orders_to_regimen(drug_orders)
    # Stavudine Lamivudine Neviripine, Stavudine Lamivudine
    drug_orders = [create(:drug_inventory_id => 5), create(:drug_inventory_id => 1)]
    assert_equal concept(:arv_first_line_regimen128), DrugOrder.drug_orders_to_regimen(drug_orders)
  end
  
  def test_should_determine_drug_regimen_from_drug_orders_for_arv_first_line_regimen_alternative
    # Zidovudine Lamivudine, Nevirapine
    drug_orders = [create(:drug_inventory_id => 8), create(:drug_inventory_id => 9)]
    assert_equal concept(:arv_first_line_regimen_alternatives129), DrugOrder.drug_orders_to_regimen(drug_orders)
    # Stavudine Lamivudine, Efavirenz
    drug_orders = [create(:drug_inventory_id => 1), create(:drug_inventory_id => 7)]
    assert_equal concept(:arv_first_line_regimen_alternatives129), DrugOrder.drug_orders_to_regimen(drug_orders)
  end
  
  def test_should_determine_drug_regimen_from_drug_orders_for_arv_second_line_regimen
    # Zidovudine Lamivudine, Tenofovir, Lopinavir/Ritonavir
    drug_orders = [create(:drug_inventory_id => 8), create(:drug_inventory_id => 14), create(:drug_inventory_id => 17)]
    assert_equal concept(:arv_second_line_regimen), DrugOrder.drug_orders_to_regimen(drug_orders)
    # Didanosine, Abacavir, Lopinavir/Ritonavir
    drug_orders = [create(:drug_inventory_id => 13), create(:drug_inventory_id => 10), create(:drug_inventory_id => 17)]
    assert_equal concept(:arv_second_line_regimen), DrugOrder.drug_orders_to_regimen(drug_orders)
  end
  
  def test_should_determine_drug_regimen_from_drug_orders_for_unknown_regimen
    # Zidovudine Lamivudine, Abacavir
    drug_orders = [create(:drug_inventory_id => 8), create(:drug_inventory_id => 10)]
    assert_nil DrugOrder.drug_orders_to_regimen(drug_orders)
    # Nevirapine
    drug_orders = [create(:drug_inventory_id => 9)]
    assert_nil DrugOrder.drug_orders_to_regimen(drug_orders)
  end

  def test_should_return_nil_regimen_if_drug_orders_is_nil
    assert_equal nil, DrugOrder.drug_orders_to_regimen([nil])
  end

  def test_should_return_given_dosage
    drug_orders = [drug_order(:andreas_stavudine_30_lamivudine_150_nevirapine_200)]
    assert_equal ["Stavudine 30 Lamivudine 150 Nevirapine 200,Morning,1.0", "Stavudine 30 Lamivudine 150 Nevirapine 200,Evening,1.0"], DrugOrder.given_drugs_dosage(drug_orders)  
  end  
  
  def test_should_return_amount_given_last_time
    patient = patient(:andreas)
    date = "2007-03-05".to_date
    assert_equal patient.drugs_given_last_time(date).map{|drug,quantity|["#{drug.name} #{quantity}"]}[0].to_s,"Stavudine 30 Lamivudine 150 Nevirapine 200 60"
  end  
  
private

  def create(options={})
    DrugOrder.create(drug_order_default_values.merge(options))
  end  

end
