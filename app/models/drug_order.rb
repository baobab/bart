class DrugOrder < OpenMRS
  set_table_name "drug_order"
  set_primary_key "drug_order_id"
  belongs_to :drug, :foreign_key => :drug_inventory_id
  belongs_to :order

  def to_s
    "#{self.drug.name}: #{self.quantity} (ARV: #{self.arv?})"
  end

  def to_prescription_s
    s = "#{self.drug.name rescue 'Unknown'}: "
    s << "#{self.quantity}#{self.drug.units} " if self.quantity
    s << "#{self.drug.dosage_form rescue 'Units'} " if self.drug && self.drug.dosage_form
    if self.frequency && self.units
      s << "#{self.frequency}: #{self.units}" 
    else
      s << "No prescription given"
    end    
    s
  end

  def date
    return self.encounter.encounter_datetime.to_date rescue nil
  end

  def encounter
    return self.order.encounter
  end

  def arv?
    return self.drug.arv?
  end

  # This captures hanging pills
  def quantity_remaining_from_last_order
    quantity_remaining = 0
    self.prescription_encounter.observations.find_by_concept_name("Whole tablets remaining and brought to clinic").each{|observation|
      next if observation.value_numeric.nil?  
      # TODO This is a bad hack to handle old dirty data which saved all tablet remaining calculations as SL 30/150
      quantity_remaining += observation.value_numeric if observation.drug == self.drug or (self.drug.name.match(/Stavudine/) and observation.drug == Drug.find_by_name("Stavudine 30 Lamivudine 150"))      
    } unless self.prescription_encounter.nil?
    return quantity_remaining
  end

  def prescriptions
    return self.prescription_encounter.to_prescriptions.each{|prescription|
      next unless prescription.drug == self.drug
    }.compact unless self.prescription_encounter.nil?
  end

  def daily_consumption
#   Need daily consumption
#   Number of units given
#   Days since drugs given
    daily_consumption = 0
    # Look for the presciption that corresponds with the current drug_order
    self.prescriptions.each{|prescription|
      daily_consumption += prescription.dose_amount if prescription.drug == self.drug and prescription.frequency.match(/Morning|Evening|Daily/)
      daily_consumption += prescription.dose_amount/7.0 if prescription.frequency.match(/Weekly/) # Just an example
    } unless self.prescriptions.nil?
    if daily_consumption != 0
      return daily_consumption
    else
      # TODO HACK
      # If we can't figure out the daily consumption from previous records then assume 2
      # This will break for other types of prescriptions
      # Hopefully this is not a widespread problem
      return 2
    end
  end

  def quantity_including_amount_remaining_from_last_order
    self.quantity + self.quantity_remaining_from_last_order
  end
  
  def self.recommended_art_prescription(weight)
    regimens = Hash.new
    Regimen.all_combinations.each{|regimen|
      regimens[regimen.regimen] = Array.new if regimens[regimen.regimen].nil?
      regimens[regimen.regimen] << regimen.to_drug_order if weight >= regimen.min_weight and weight < regimen.max_weight
    }
    return regimens
  end

  # Takes an array of drug orders and determines which ARV regimen it is for
  def self.drug_orders_to_regimen(drug_orders)  
    return nil if drug_orders.blank? || drug_orders.compact.blank?
    drug_orders_hash_key = "#{drug_orders.map{|d|d.drug_order_id}.sort.join(',')}"
    @@drug_orders_hash ||= Hash.new
    return @@drug_orders_hash[drug_orders_hash_key] if @@drug_orders_hash.has_key?(drug_orders_hash_key)
    regimens = Concept.find_by_sql("
SELECT parent_concept.*
FROM (
  SELECT regimen_ingredient.concept_id
  FROM drug_order
  INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
  INNER JOIN drug_ingredient as dispensed_ingredient ON drug.concept_id = dispensed_ingredient.concept_id
  INNER JOIN drug_ingredient as regimen_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id 
  INNER JOIN concept as regimen_concept ON regimen_ingredient.concept_id = regimen_concept.concept_id 
  WHERE drug_order_id IN (#{drug_orders_hash_key}) AND regimen_concept.class_id = 18
  GROUP BY regimen_ingredient.concept_id, regimen_ingredient.ingredient_id) as satisfied_ingredients
INNER JOIN concept_set AS parent_concept_set ON parent_concept_set.concept_id = satisfied_ingredients.concept_id
INNER JOIN concept AS parent_concept ON parent_concept.concept_id = parent_concept_set.concept_set
GROUP BY satisfied_ingredients.concept_id
HAVING count(*) = (SELECT count(*) FROM drug_ingredient WHERE drug_ingredient.concept_id = satisfied_ingredients.concept_id)")
    @@drug_orders_hash[drug_orders_hash_key] = nil if regimens.blank?
    return nil if regimens.blank?
    @@drug_orders_hash[drug_orders_hash_key] = regimens.first
    regimens.first
=begin  
    regimens = Concept.find_by_sql("
      SELECT parent_concept.*
      FROM drug_order
      INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
      INNER JOIN drug_ingredient as dispensed_ingredient ON drug.concept_id = dispensed_ingredient.concept_id
      INNER JOIN drug_ingredient as regimen_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id 
      INNER JOIN concept as regimen_concept ON regimen_ingredient.concept_id = regimen_concept.concept_id 
      INNER JOIN concept_set AS parent_concept_set ON parent_concept_set.concept_id = regimen_concept.concept_id
      INNER JOIN concept AS parent_concept ON parent_concept.concept_id = parent_concept_set.concept_set
      WHERE drug_order_id IN (#{drug_orders.map{|d|d.drug_order_id}.join(',')}) AND regimen_concept.class_id = 18
      GROUP BY regimen_ingredient.concept_id
      HAVING count(*) = (SELECT count(*) FROM drug_ingredient WHERE drug_ingredient.concept_id = regimen_ingredient.concept_id)")
    return nil if regimens.blank?
    regimens.first
=end    
=begin    
    regimens = Concept.find_by_sql("
      SELECT parent_concept.*
      FROM concept AS regimen_concept
      INNER JOIN concept_set ON concept_set.concept_id = regimen_concept.concept_id
      INNER JOIN concept AS parent_concept ON parent_concept.concept_id = concept_set.concept_set
      WHERE regimen_concept.class_id = 18 AND NOT EXISTS (
        SELECT *
        FROM drug_ingredient AS regimen_ingredient
        INNER JOIN drug_order ON drug_order.drug_order_id IN (#{drug_orders.map{|d|d.drug_order_id}.join(',')})
        INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
        LEFT JOIN drug_ingredient as dispensed_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id AND drug.concept_id = dispensed_ingredient.concept_id
        WHERE regimen_ingredient.concept_id = regimen_concept.concept_id AND dispensed_ingredient.ingredient_id IS NULL)")
    return nil if regimens.blank?
    regimens.first
=end    
=begin
    #first, first alt, second line
    combined_drug_orders = drug_orders.collect{|drug_order|drug_order.drug.name}.join("+")
    if combined_drug_orders.match(/Stavudine/) && combined_drug_orders.match(/Lamivudine/) && combined_drug_orders.match(/Nevirapine/)
      return Concept.find_by_name("ARV First line regimen")
    elsif combined_drug_orders.match(/Zidovudine/) && combined_drug_orders.match(/Lamivudine/) && combined_drug_orders.match(/Nevirapine/)
      return Concept.find_by_name("ARV First line regimen alternatives")
    elsif combined_drug_orders.match(/Stavudine/) && combined_drug_orders.match(/Lamivudine/) && combined_drug_orders.match(/Efavirenz/)
      return Concept.find_by_name("ARV First line regimen alternatives")
    elsif combined_drug_orders.match(/Zidovudine/) && combined_drug_orders.match(/Lamivudine/) && combined_drug_orders.match(/Tenofovir/) && combined_drug_orders.match(/Lopinavir/) && combined_drug_orders.match(/Ritonavir/)
      return Concept.find_by_name("ARV Second line regimen")
    elsif combined_drug_orders.match(/Didanosine/) && combined_drug_orders.match(/Abacavir/) && combined_drug_orders.match(/Lopinavir/) && combined_drug_orders.match(/Ritonavir/)
      return Concept.find_by_name("ARV Second line regimen")
    else
      # Unknown drug regimen
      # TODO: Fix this!
      return nil
    end
=end    
  end
  
  
  
  # This could return an array of regimens (in case a prescription matches multiple regimens)
  def self.drug_orders_to_sub_regimens(drug_orders)  
    Concept.find_by_sql("
      SELECT * 
      FROM concept 
      WHERE concept.concept_id IN (
        SELECT DISTINCT regimen_concept.concept_id as regimen
        FROM drug_ingredient AS regimen_ingredient
        INNER JOIN concept AS regimen_concept ON regimen_concept.class_id = 18
        INNER JOIN drug_order ON drug_order.drug_order_id IN (3,1)
        INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
        LEFT JOIN drug_ingredient as dispensed_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id AND drug.concept_id = dispensed_ingredient.concept_id
        WHERE regimen_ingredient.concept_id = regimen_concept.concept_id AND dispensed_ingredient.ingredient_id IS NOT NULL
        GROUP BY dispensed_ingredient.ingredient_id
      )")
=begin  

    # 18 is the concept_class for regimens
    Concept.find_by_sql("
      SELECT regimen.*
      FROM drug_order
      INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
      INNER JOIN drug_ingredient as dispensed_ingredient ON drug.concept_id = dispensed_ingredient.concept_id
      INNER JOIN drug_ingredient as regimen_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id 
      INNER JOIN concept as regimen ON regimen_ingredient.concept_id = regimen.concept_id 
      WHERE drug_order_id IN (#{drug_orders.map{|d|d.drug_order_id}.join(',')}) AND regimen.class_id = 18
      GROUP BY regimen_ingredient.concept_id
      HAVING count(*) = (SELECT count(*) FROM drug_ingredient WHERE drug_ingredient.concept_id = regimen_ingredient.concept_id)")
=end
=begin
    Concept.find_by_sql("
      SELECT *
      FROM concept
      WHERE class_id = 18 AND concept_id NOT IN (
        SELECT regimen_ingredient.concept_id
        FROM drug_ingredient AS regimen_ingredient
        INNER JOIN concept as regimen ON regimen_ingredient.concept_id = regimen.concept_id 
        INNER JOIN drug_order ON drug_order.drug_order_id IN (#{drug_orders.map{|d|d.drug_order_id}.join(',')})
        INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
        LEFT JOIN drug_ingredient as dispensed_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id AND drug.concept_id = dispensed_ingredient.concept_id

    Concept.find_by_sql("
      SELECT *
      FROM concept AS regimen_concept
      WHERE class_id = 18 AND NOT EXISTS (
        SELECT *
        FROM drug_ingredient AS regimen_ingredient
        INNER JOIN drug_order ON drug_order.drug_order_id IN (#{drug_orders.map{|d|d.drug_order_id}.join(',')})
        INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
        LEFT JOIN drug_ingredient as dispensed_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id AND drug.concept_id = dispensed_ingredient.concept_id
        WHERE regimen_ingredient.concept_id = regimen_concept.concept_id AND dispensed_ingredient.ingredient_id IS NULL)")
=end
  end
    
  def self.given_drugs_dosage(drug_orders)
    return nil if drug_orders.blank?
    orders = Array.new()
    drug_orders.collect{|order|
      next if order.drug.name == "Insecticide Treated Net"
      prescriptions = order.prescription_encounter.to_prescriptions rescue []
      prescriptions.each{|p| orders << "#{order.drug.name},#{p.frequency},#{p.dose_amount.to_f}" }
      orders << "#{order.drug.name},no prescription,__" if prescriptions.blank?
    }
    return orders.uniq
  end 
   
  def prescription_encounter
    dispensation_encounter = self.encounter
    # use the date from the dispensing encounter to find the corresponding prescription encounter
    prescription_encounter = dispensation_encounter.patient.encounters.find_by_type_name_and_date("ART Visit", Date.parse(dispensation_encounter.encounter_datetime.to_s)).last
  end
  
  def self.patient_adherence(patient,visit_date=Date.today)
    expected_amount_remaining = 0 
    drugs_dispensed_last_time = Hash.new
    previous_art_drug_orders = patient.previous_art_drug_orders(visit_date)
    previous_art_visit_date = previous_art_drug_orders.last.encounter.encounter_datetime.to_s.to_date
    amount_given_last_time = self.amount_given_last_time(patient,previous_art_visit_date).to_s.to_i rescue 0

    previous_art_drug_orders.collect{|drug_order|
      drugs_dispensed_last_time[drug_order.drug] = true
    }

    drugs_dispensed_last_time = drugs_dispensed_last_time.keys
    current_date = visit_date
    art_quantities_including_amount_remaining_after_previous_visit = patient.art_quantities_including_amount_remaining_after_previous_visit(current_date)
    art_amount_remaining_if_adherent = patient.art_amount_remaining_if_adherent(current_date)
    num_days_overdue_by_drug = patient.num_days_overdue_by_drug(current_date)

    drugs_dispensed_last_time.each{|drug|
      expected_amount_remaining+= art_amount_remaining_if_adherent[drug] rescue 0
    } 

    pills_remaining = self.amount_given_last_time(patient,previous_art_visit_date)
    amount_remaining = 0
    pills_remaining.map{|x|amount_remaining+=x.value_numeric}
    amount_remaining = amount_remaining.round 
    puts "#{amount_remaining}.... #{expected_amount_remaining}"
    puts "#{amount_given_last_time}.... #{expected_amount_remaining}..................#{previous_art_visit_date}"
    number_missed = amount_remaining - expected_amount_remaining
    return (100*(amount_given_last_time - amount_remaining) / (amount_given_last_time - expected_amount_remaining)).round
  end  

end


### Original SQL Definition for drug_order #### 
#   `drug_order_id` int(11) NOT NULL auto_increment,
#   `order_id` int(11) NOT NULL default '0',
#   `drug_inventory_id` int(11) default '0',
#   `dose` int(11) default NULL,
#   `units` varchar(255) default NULL,
#   `frequency` varchar(255) default NULL,
#   `prn` tinyint(1) NOT NULL default '0',
#   `complex` tinyint(1) NOT NULL default '0',
#   `quantity` int(11) default NULL,
#   PRIMARY KEY  (`drug_order_id`),
#   KEY `inventory_item` (`drug_inventory_id`),
#   CONSTRAINT `extends_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`),
#   CONSTRAINT `inventory_item` FOREIGN KEY (`drug_inventory_id`) REFERENCES `drug` (`drug_id`)
