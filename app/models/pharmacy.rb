class Pharmacy < OpenMRS
  set_table_name "pharmacy_obs"
  set_primary_key "pharmacy_module_id"

  named_scope :active, :conditions => ['voided = 0']
=begin
  def after_save
    super
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    if self.pharmacy_encounter_type == encounter_type
     Pharmacy.reset(self.drug_id)
    end
  end
=end

  def self.alter(drug, quantity, date = nil , reason = nil)
    encounter_type = PharmacyEncounterType.find_by_name("Tins removed").id
    current_stock =  Pharmacy.new()
    current_stock.pharmacy_encounter_type = encounter_type
    current_stock.drug_id = drug.id
    current_stock.encounter_date = date
    current_stock.value_numeric = quantity.to_f
    current_stock.value_text = reason
    current_stock.save
  end

  def self.drug_dispensed_stock_adjustment(drug_id,quantity,encounter_date,reason = nil)
=begin
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    number_of_pills = Pharmacy.current_stock(drug_id) 

    current_stock =  Pharmacy.new()
    current_stock.pharmacy_encounter_type = encounter_type
    current_stock.drug_id = drug_id
    current_stock.encounter_date = Date.today
    current_stock.value_numeric = (number_of_pills - quantity)
    current_stock.save

    unless reason.blank?
      current_stock =  Pharmacy.new()
      current_stock.pharmacy_encounter_type = PharmacyEncounterType.find_by_name("Edited stock").id
      current_stock.drug_id = drug_id
      current_stock.encounter_date = encounter_date
      current_stock.value_numeric = quantity
      current_stock.value_text = reason
      current_stock.save
    end
    #self.reset(drug_id)
=end
  end

  def self.reset(drug_id=nil)
=begin
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
=end
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

  def self.dispensed_drugs_to_date(drug_id)
    result = ActiveRecord::Base.connection.select_value <<EOF
SELECT sum(quantity) FROM encounter e 
INNER JOIN orders o ON e.encounter_id=o.encounter_id
INNER JOIN drug_order d ON o.order_id=d.order_id
WHERE o.voided=0 AND drug_inventory_id=#{drug_id} 
AND e.encounter_datetime <='#{Date.today} 23:59:59'
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
     :order => "encounter_date DESC,date_created DESC").value_numeric.to_i rescue 0
  end

  def self.current_stock_as_from(drug_id,start_date=Date.today,end_date=Date.today)
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id

    return Pharmacy.active.find(:first,
     :conditions => ["drug_id=? AND pharmacy_encounter_type=?
     AND encounter_date <=?",drug_id,encounter_type,end_date],
     :order => "encounter_date DESC,date_created DESC").value_numeric rescue 0

=begin
    total_dispensed_to_date = Pharmacy.dispensed_drugs_since(drug_id,first_date)
    current_stock = self.current_stock(drug_id)

    pills = Pharmacy.dispensed_drugs_since(drug_id,start_date,end_date)
    total_dispensed = Pharmacy.total_delivered(drug_id,start_date,end_date)
=end

    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    first_date = self.active.find(:first,:conditions =>["drug_id =?",drug_id],:order => "encounter_date").encounter_date

    total_stock_to_given_date = Pharmacy.active.find(:all,
     :conditions => ["drug_id=? AND pharmacy_encounter_type=? AND encounter_date >=?
     AND encounter_date <=?",drug_id,encounter_type,first_date,end_date],
     :order => "encounter_date DESC,date_created DESC").map{|stock|stock.value_numeric}

    total_stock_to_given_date  = total_stock_to_given_date.sum
    total_dispensed_to_given_date = Pharmacy.dispensed_drugs_since(drug_id,first_date,end_date)

    return total_stock_to_given_date - total_dispensed_to_given_date
  end

  def self.new_delivery(drug_id,pills,date,encounter_type = nil,expiry_date = nil,delivery_barcode = nil)

#    raise "#{date} ---- #{drug_id} --- #{pills} --- #{encounter_type} --- #{expiry_date}"
    
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id if encounter_type.blank?
    delivery =  self.new()
    delivery.pharmacy_encounter_type = encounter_type
    delivery.drug_id = drug_id
    delivery.encounter_date = date
    delivery.expiry_date = expiry_date unless expiry_date.blank?
    delivery.value_numeric = pills
    delivery.value_text = delivery_barcode
    delivery.save

    if expiry_date
      if expiry_date.to_date < Date.today
        delivery.voided = 1
        return delivery.save
      end  
    end 
=begin
#cul current stock
    total_dispensed_from_given_date = Pharmacy.dispensed_drugs_since(drug_id,date)
    first_date = self.active.find(:first,:order => "encounter_date").encounter_date
    total_dispensed = Pharmacy.dispensed_drugs_since(drug_id,first_date)
    total_dispensed_to_given_date = (total_dispensed - total_dispensed_from_given_date)

   
    stock_before_given_date  = nil
    total_stock_before_given_date = self.active.find(:all,:conditions =>["pharmacy_encounter_type = 2 AND encounter_date < ?",date])
    
    if total_stock_before_given_date
      stock_before_given_date = total_stock_before_given_date.map{|stock|stock.value_numeric} || [0]
    end  

    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id 
    unless stock_before_given_date.blank?
      delivery =  self.new()
      delivery.pharmacy_encounter_type = encounter_type
      delivery.drug_id = drug_id
      delivery.encounter_date = date - 1.day
      delivery.value_numeric = (stock_before_given_date.sum -  total_dispensed_to_given_date)
      delivery.save
    end rescue nil

    stock_after_given_date = self.active.find(:all,:conditions =>["pharmacy_encounter_type = 2 AND encounter_date >= ?",
      date]).map{|stock|stock.value_numeric} || [0]

    delivery =  self.new()
    delivery.pharmacy_encounter_type = encounter_type
    delivery.drug_id = drug_id
    delivery.encounter_date = Date.today
    delivery.value_numeric = (stock_after_given_date.sum - total_dispensed_from_given_date) + (stock_before_given_date.sum -  total_dispensed_to_given_date)
    delivery.save
=end
  end

  def Pharmacy.total_delivered(drug_id,start_date=nil,end_date=nil)
    total = 0
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    if start_date.blank? and end_date.blank?
      Pharmacy.active.find(:all,
       :conditions => ["drug_id=? AND pharmacy_encounter_type=?",drug_id,encounter_type],
       :order => "encounter_date DESC,date_created DESC").map{|d|total+=d.value_numeric}
    else   
      Pharmacy.active.find(:all,
       :conditions => ["drug_id=? AND pharmacy_encounter_type=? 
       AND encounter_date >=? AND encounter_date <=?",drug_id,encounter_type,start_date,end_date],
       :order => "encounter_date DESC,date_created DESC").map{|d|total+=d.value_numeric}
    end 
    total
  end

  def self.first_delivery_date
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    Pharmacy.active.find(:first,:conditions => ["pharmacy_encounter_type=?",
      encounter_type],:order => "encounter_date ASC,date_created ASC").encounter_date rescue nil
  end

  def self.valide_months
    first_delivery_month = self.first_delivery_date.month
    months = ''
    1.upto(12).map do |number|
      next if number < first_delivery_month
      if months.blank?
        months = ("#{Date.today.year}-#{number}-01").to_date.strftime("%B")
      else
        months +='|' + ("#{Date.today.year}-#{number}-01").to_date.strftime("%B")
      end
    end
    return months
  end

  def self.valide_days
    first_delivery_day = self.first_delivery_date.day
    days = ''
    1.upto(31).map do |number|
      next if number < first_delivery_day
      if days.blank?
        days = number.to_s
      else
        days += "|#{number}"
      end
    end
    return days
  end

  def self.remove_stock(encounter_id)
    encounter = Pharmacy.active.find(encounter_id)
    pills_to_removed =  encounter.value_numeric
    first_date = self.active.find(:first,:order => "encounter_date").encounter_date
    total_dispensed_to_date = Pharmacy.dispensed_drugs_since(encounter.drug_id,first_date)
    current_stock = self.current_stock(encounter.drug_id)

    remaining_stock = (current_stock - pills_to_removed) 
    if remaining_stock >= total_dispensed_to_date
      encounter.voided = 1
      encounter.save
      delivery =  self.new()
      delivery.pharmacy_encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
      delivery.drug_id = encounter.drug_id
      delivery.encounter_date = Date.today
      delivery.value_numeric = remaining_stock
      return delivery.save
    end
  end

  def self.relocated(drug_id,start_date,end_date = Date.today)
    encounter_type = PharmacyEncounterType.find_by_name('Tins removed').id
    result = ActiveRecord::Base.connection.select_value <<EOF
SELECT sum(value_numeric) FROM pharmacy_obs p 
INNER JOIN pharmacy_encounter_type t ON t.pharmacy_encounter_type_id = p.pharmacy_encounter_type
AND pharmacy_encounter_type_id = #{encounter_type}
WHERE p.voided=0 AND drug_id=#{drug_id} 
AND p.encounter_date >='#{start_date} 00:00:00' AND p.encounter_date <='#{end_date} 23:59:59'
GROUP BY drug_id ORDER BY encounter_date
EOF
     result.to_i rescue 0
   end

  def self.receipts(drug_id,start_date,end_date = Date.today)
    encounter_type = PharmacyEncounterType.find_by_name('New deliveries').id
    result = ActiveRecord::Base.connection.select_value <<EOF
SELECT sum(value_numeric) FROM pharmacy_obs p 
INNER JOIN pharmacy_encounter_type t ON t.pharmacy_encounter_type_id = p.pharmacy_encounter_type
AND pharmacy_encounter_type_id = #{encounter_type}
WHERE p.voided=0 AND drug_id=#{drug_id} 
AND p.encounter_date >='#{start_date} 00:00:00' AND p.encounter_date <='#{end_date} 23:59:59'
GROUP BY drug_id ORDER BY encounter_date
EOF
     result.to_i rescue 0
   end

  def self.expected(drug_id,start_date,end_date)
    encounter_type_ids = PharmacyEncounterType.find(:all).collect{|e|e.id}
    start_date = Pharmacy.active.find(:first,:conditions =>["pharmacy_encounter_type IN (?)",
      encounter_type_ids],:order =>'encounter_date ASC,date_created ASC').encounter_date rescue start_date

    dispensed_drugs = self.dispensed_drugs_since(drug_id,start_date,end_date)
    relocated = self.relocated(drug_id,start_date,end_date)
    receipts = self.receipts(drug_id,start_date,end_date)
    
    return (receipts - (dispensed_drugs + relocated))
  end

  def self.verify_stock_count(drug_id,start_date,end_date)
    encounter_type_id = PharmacyEncounterType.find_by_name('Tins currently in stock').id
    start_date = Pharmacy.active.find(:first,
      :conditions =>["drug_id = ? AND pharmacy_encounter_type = ? AND encounter_date = ?",
      drug_id,encounter_type_id,end_date],
      :order =>'encounter_date DESC,date_created DESC').value_numeric rescue 0
  end

  def self.current_drug_stock(drug_id)
    start_date = self.first_delivery_date
    self.expected(drug_id,start_date,Date.today)
  end

end
