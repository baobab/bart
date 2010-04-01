class Pharmacy < OpenMRS
  set_table_name "pharmacy_obs"
  set_primary_key "pharmacy_module_id"

  named_scope :active, :conditions => ['voided = 0']

  def after_save
    super
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    if self.pharmacy_encounter_type == encounter_type
     Pharmacy.reset_current_stock(self.drug_id,self.value_numeric,encounter_type,self.encounter_date)
    end
  end

  def self.reset_current_stock(drug_id,new_quantity,encounter_type,encounter_date)
    current_stock_encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    number_of_pills_current_stock = self.active.find(:first,
      :conditions => ["drug_id=? AND pharmacy_encounter_type=?",
      drug_id,current_stock_encounter_type],
      :order => "encounter_date DESC,date_created DESC").value_numeric rescue 0

    number_of_pills = (number_of_pills_current_stock + new_quantity) 
    current_stock =  Pharmacy.new()
    current_stock.pharmacy_encounter_type = current_stock_encounter_type
    current_stock.drug_id = drug_id
    current_stock.encounter_date = encounter_date
    current_stock.value_numeric = number_of_pills
    current_stock.save
  end

  def self.drug_dispensed_stock_adjustment(drug_id,quantity,encounter_date)
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    number_of_pills = self.active.find(:first,
      :conditions => ["drug_id=? AND pharmacy_encounter_type=?",
      drug_id,encounter_type],
      :order => "encounter_date DESC,date_created DESC").value_numeric rescue 0

    current_stock =  Pharmacy.new()
    current_stock.pharmacy_encounter_type = encounter_type
    current_stock.drug_id = drug_id
    current_stock.encounter_date = encounter_date
    current_stock.value_numeric = (number_of_pills - quantity)
    current_stock.save
  end

  def self.reset
    stock = {}
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    drug_stock = Pharmacy.active.find(:all,
      :conditions => ["pharmacy_encounter_type=?",encounter_type],
      :group => "drug_id",:order => "date_created DESC,encounter_date DESC")
    drug_stock.each{|stock|
      pills = self.dispensed_drugs_since(stock.drug_id,stock.encounter_date)
      next if stock.value_numeric.to_i == 0
      current_stock =  Pharmacy.new()
      current_stock.pharmacy_encounter_type = encounter_type
      current_stock.drug_id = stock.drug_id
      current_stock.encounter_date = Date.today
      puts "#{stock.value_numeric} - #{pills}"
      current_stock.value_numeric = (stock.value_numeric - pills)
      current_stock.save
    }
  end
      
  def self.dispensed_drugs_since(drug_id,date,end_date = Date.today)
    result = ActiveRecord::Base.connection.select_value <<EOF
SELECT sum(quantity) FROM encounter e 
INNER JOIN orders o ON e.encounter_id=o.encounter_id
INNER JOIN drug_order d ON o.order_id=d.order_id
WHERE o.voided=0 AND drug_inventory_id=#{drug_id} 
AND e.encounter_datetime >='#{date} 00:00:00' AND e.encounter_datetime <='#{end_date} 23:59:59'
group by drug_inventory_id order by encounter_datetime
EOF
     result.to_i rescue 0
   end

  def self.prescribed_drugs_since(drug_id,start_date,end_date = Date.today)
    time_period = Concept.find_by_name("Prescription time period").id
    dose = Concept.find_by_name("Prescribed dose").id
    counted_at_clinic = Concept.find_by_name("Whole tablets remaining and brought to clinic").id
    art_encounter_type = EncounterType.find_by_name("ART Visit").id
    results = ActiveRecord::Base.connection.select_all <<EOF
SELECT obs.value_text AS frequency,obs.value_numeric AS pills,(SELECT c.value_numeric FROM obs c WHERE c.encounter_id=obs.encounter_id AND c.concept_id=#{counted_at_clinic} AND obs.value_drug=c.value_drug) AS counted_at_clinic,
(SELECT o.value_text FROM obs o WHERE o.encounter_id=obs.encounter_id AND o.concept_id=#{time_period}) 
AS period 
FROM obs INNER JOIN encounter e ON e.encounter_id=obs.encounter_id
WHERE obs.value_drug=#{drug_id} AND obs.value_numeric <> 0 AND e.encounter_type=#{art_encounter_type} AND voided=0 
AND e.encounter_datetime >='#{start_date} 00:00:00' AND e.encounter_datetime <='#{end_date} 23:59:59'
AND obs.concept_id=#{dose}
EOF
    total_prescribed = 0
    drug_name = Drug.find(drug_id).name
    results.each{|result|
      frequency = result["frequency"] ; pills = result["pills"].to_f rescue 0
      counted_at_clinic = result["counted_at_clinic"].to_i rescue 0
      time_period = result["period"].titlecase rescue nil
      next if time_period.blank? ; next if frequency.blank?
      prescription = Prescription.new(drug_name,frequency,pills,time_period,counted_at_clinic)      
      total_prescribed+= prescription.quantity
    }
    total_prescribed
  end

  def self.current_stock(drug_id)
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    Pharmacy.active.find(:first,
     :conditions => ["drug_id=? AND pharmacy_encounter_type=?",drug_id,encounter_type],
     :order => "date_created DESC,encounter_date DESC").value_numeric.to_i rescue 0
  end

  def self.current_stock_as_from(drug_id,start_date=Date.today,end_date=Date.today)
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    Pharmacy.active.find(:first,
     :conditions => ["drug_id=? AND pharmacy_encounter_type=? AND encounter_date >=?
     AND encounter_date <=?",drug_id,encounter_type,start_date,end_date],
     :order => "date_created DESC,encounter_date DESC").value_numeric.to_i rescue 0
  end

end
