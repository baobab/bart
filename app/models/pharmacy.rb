class Pharmacy < OpenMRS
  set_table_name "pharmacy_obs"
  set_primary_key "pharmacy_module_id"

  named_scope :active, :conditions => ['voided = 0']

  def after_save
    super
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    if self.pharmacy_encounter_type == encounter_type
     Pharmacy.reset(self.drug_id)
    end
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

  def self.reset(drug_id=nil)
    stock_encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    new_deliveries = PharmacyEncounterType.find_by_name("New deliveries").id
    
    if drug_id.blank?
      drug_stock = Pharmacy.active.find(:all,
        :conditions => ["pharmacy_encounter_type=?",new_deliveries],
        :group => "drug_id",:order => "date_created ASC,encounter_date ASC")
    else
      drug_stock = Pharmacy.active.find(:all,
        :conditions => ["pharmacy_encounter_type=? AND drug_id=?",new_deliveries,drug_id],
        :group => "drug_id",:order => "date_created ASC,encounter_date ASC")
    end
    drug_stock.each{|stock|
      first_date_range = Report.cohort_range(stock.encounter_date) rescue nil
      pills = Pharmacy.dispensed_drugs_since(stock.drug_id,stock.encounter_date,first_date_range.last)
      total_dispensed = Pharmacy.total_delivered(stock.drug_id,stock.encounter_date,first_date_range.last)

      current_stock =  Pharmacy.new()
      current_stock.pharmacy_encounter_type = stock_encounter_type
      current_stock.drug_id = stock.drug_id
      current_stock.encounter_date = first_date_range.last
      current_stock.value_numeric = (total_dispensed - pills)
      current_stock.save

      dates = self.date_ranges(stock.encounter_date) 
      dates.each{|date|
        given_range = Report.cohort_range(date) rescue nil
        start_date = given_range.first ; end_date = given_range.last
        end_date = Date.today if end_date == Report.cohort_range(Date.today).last
        pills = Pharmacy.dispensed_drugs_since(stock.drug_id,first_date_range.first,end_date)
        total_dispensed = Pharmacy.total_delivered(stock.drug_id,first_date_range.first,end_date)

        current_stock =  Pharmacy.new()
        current_stock.pharmacy_encounter_type = stock_encounter_type
        current_stock.drug_id = stock.drug_id
        current_stock.encounter_date = end_date
        current_stock.value_numeric = (total_dispensed - pills)
        current_stock.save
      } unless dates.blank?
    }
    true
  end
     
  def self.date_ranges(date)    
    current_range =[]
    current_range << Report.cohort_range(date).last
    end_date = Report.cohort_range(Date.today).last
    while current_range.last < end_date
      current_range << Report.cohort_range(current_range.last + 1.day).last
    end  
    current_range[1..-1] rescue nil
  end

  def Pharmacy.dispensed_drugs_since(drug_id,date,end_date = Date.today)
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

  def Pharmacy.prescribed_drugs_since(drug_id,start_date,end_date = Date.today)
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

  def Pharmacy.current_stock_as_from(drug_id,start_date=Date.today,end_date=Date.today)
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    Pharmacy.active.find(:first,
     :conditions => ["drug_id=? AND pharmacy_encounter_type=? AND encounter_date >=?
     AND encounter_date <=?",drug_id,encounter_type,start_date,end_date],
     :order => "date_created DESC,encounter_date DESC").value_numeric.to_i rescue 0
  end

  def self.new_delivery(drug_id,pills,date,encounter_type = nil)
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id if encounter_type.blank?
    delivery =  Pharmacy.new()
    delivery.pharmacy_encounter_type = encounter_type
    delivery.drug_id = drug_id
    delivery.encounter_date = date
    delivery.value_numeric = pills
    delivery.save
  end

  def Pharmacy.total_delivered(drug_id,start_date=nil,end_date=nil)
    total = 0
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    if start_date.blank? and end_date.blank?
      Pharmacy.active.find(:all,
       :conditions => ["drug_id=? AND pharmacy_encounter_type=?",drug_id,encounter_type],
       :order => "date_created DESC,encounter_date DESC").map{|d|total+=d.value_numeric}
    else   
      Pharmacy.active.find(:all,
       :conditions => ["drug_id=? AND pharmacy_encounter_type=? 
       AND encounter_date >=? AND encounter_date <=?",drug_id,encounter_type,start_date,end_date],
       :order => "date_created DESC,encounter_date DESC").map{|d|total+=d.value_numeric}
    end 
    total
  end

  def first_delivery_date(drug_id)
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    Pharmacy.active.find(:first,:conditions => ["drug_id=? AND pharmacy_encounter_type=?",drug_id,encounter_type],
    :order => "date_created ASC,encounter_date ASC").encounter_date rescue nil
  end

end
