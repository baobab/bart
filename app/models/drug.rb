class Drug < OpenMRS
  set_table_name "drug"
  has_many :obs, :foreign_key => :value_drug
  has_many :drug_orders, :foreign_key => :drug_inventory_id
  has_many :barcodes, :class_name => "DrugBarcode",  :foreign_key => :drug_id
  belongs_to :concept, :foreign_key => :concept_id
  belongs_to :user, :foreign_key => :user_id
#drug_id
  set_primary_key "drug_id"

  @@drug_hash_by_name = Hash.new
  @@drug_hash_by_id = Hash.new
  self.find(:all).each{|concept|
    @@drug_hash_by_name[concept.name.downcase] = concept
    @@drug_hash_by_id[concept.id] = concept
  }

# Use the cache hash to get these fast
  def self.find_from_ids(args, options)
    super if args.length > 1 and return
    return @@drug_hash_by_id[args.first] || super
  end
  
  def self.find_by_name(drug_name)
    return @@drug_hash_by_name[drug_name.downcase] || super
  end
  
  def type
    self.concept.concept_sets.collect{|concept_set|
      concept_set.name
    }.flatten.join(", ")
  end

  ## REFACTOR! This should be done with a concept_class and seems outdated anyway!
  def arv?
    arvs = ["Stavudine Lamivudine", "Stavudine Lamivudine Nevirapine", "Efavirenz", "Zidovudine Lamivudine", "Nevirapine", "Abacavir", "Didanosine", "Lopinavir Ritonavir", "Didanosine", "Tenofovir"]
    return arvs.include?(self.concept.name)
  end

  def to_abbreviation
    case self.name
      when "Stavudine 30 Lamivudine 150"
            return "SL: "
      when "Stavudine 40 Lamivudine 150"
         return "SL: "
      when "Stavudine 30 Lamivudine 150 Nevirapine 200"
          return "SLN: " 
      when "Stavudine 40 Lamivudine 150 Nevirapine 200"
          return "SLN: "   
      when "Efavirenz 600"
          return "E: " 
      when "Zidovudine 300 Lamivudine 150"
          return "ZL: "
      when "Nevirapine 200"
           return "N: "
      when "Abacavir 300"
           return "A: "
      when "Didanosine 125"
           return "D: "
      when "Lopinavir 133 Ritonavir 33"
           return "LR: " 
      when "Didanosine 200"     
            return "D: "
      when "Tenofovir 300"     
            return "T: "
      else
        return "Oth: "
    end
  end

  # This method sets up all of the drugs and concepts according to the spreadsheet loaded in the the Regimen class
  def self.update_drugs_and_drug_concepts_from_spreadsheet
    all_combinations = Regimen.all_combinations
# loop thru all drugs on the spreadsheet - and also add Cotrimoxazole
    all_combinations.collect{|reg|reg.drug}.uniq.push("Insecticide Treated Net","Cotrimoxazole 480").each{|drug_name|
      if Drug.find_by_name(drug_name).nil?
        drug = Drug.new
        drug.name = drug_name
        drug_concept_name = drug_name.gsub(/ \d+/,"")
        #puts drug_concept_name
        #return
        drug_concept = Concept.find_by_name(drug_concept_name)
        if drug_concept.nil?
          # Create the concept for the drug if it doesn't exist
          drug_concept = Concept.new
          drug_concept.name = drug_concept_name
          drug_concept.concept_class = ConceptClass.find_by_name("Drug")
          drug_concept.concept_datatype = ConceptDatatype.find_by_name("Text")
          drug_concept.save
        end
        drug.concept = drug_concept
        if drug.name.match(/ /) # space implies two names
          drug.combination = true
        else
          drug.combination = false
        end
        drug.save
      end

    }
  end

  def month_quantity(year=Date.today.year, month=Date.today.month)
    qty = 0
    self.drug_orders.each{|drug_order|
      order_date = drug_order.order.encounter.encounter_datetime.to_date
      next unless order_date.year == year and order_date.month == month 
      next if drug_order.encounter.voided?
      qty += drug_order.quantity 
    }
    return qty
  end

  # Assign this drug to a regimen type e.g. ARV first line regimen
  # e.g.: self.add_to_regimen_type(Concept.find_by_name('ARV first line regimen')) will add this drug an ARV first line regimen drug
  def add_to_regimen_type(regimen_concept)
    return nil if regimen_concept.blank?
    drug_concept = self.concept
    return nil if drug_concept.blank? or User.current_user.nil?
    concept_set = ConceptSet.new(:concept_id => drug_concept.id, :concept_set => regimen_concept.id,
                   :creator => User.current_user.id, :date_created => Time.now)
    concept_set.save
  end
  
  def short_name
    Concept.find(self.concept_id).short_name rescue nil
  end

end

