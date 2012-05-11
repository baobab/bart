# Patient historical regimens are just a cached version of the patient regimens.
# Please see PatientRegimen for more details on how regimens are calculated.
class PatientHistoricalRegimen < ActiveRecord::Base
  set_table_name :patient_historical_regimens
  belongs_to :patient
  belongs_to :concept, :foreign_key => 'regimen_concept_id'
  belongs_to :encounter, :foreign_key =>'encounter_id'

  @@index_date = nil
  @@indexing = false
  
  def self.find(*args)
#    d = self.index_date
 #   reindex unless d && d >= Date.today
    super
  end
  
  def self.reset
    self.reindex
  end  
  
private

  def self.index_date
    return @@index_date if @@index_date && @@index_date >= Date.today    
    p = GlobalProperty.find_by_property('patient_historical_regimen_index_date')
    p ||= GlobalProperty.create(:property => 'patient_historical_regimen_index_date') 
    Date.parse(p.property_value) rescue nil    
  end
  
  def self.indexing?
    return @@indexing if @@indexing
    p = GlobalProperty.find_by_property('patient_historical_regimen_indexing')
    p ||= GlobalProperty.create(:property => 'patient_historical_regimen_indexing') 
    p.property_value == 'true' rescue false    
  end  

  def self.reindex
    raise "Sorry I am currently building the historical regimen indexes. Please refresh the page you were trying to load" if self.indexing?    

    @@index_date = Date.today 
    p = GlobalProperty.find_or_create_by_property('patient_historical_regimen_index_date')
    p.property_value = @@index_date
    p.save

    @@indexing = true
    p = GlobalProperty.find_or_create_by_property('patient_historical_regimen_indexing')
    p.property_value = @@indexing
    p.save
    
ActiveRecord::Base.connection.execute <<EOF
DELETE FROM patient_historical_regimens;
EOF

    all_patient_on_arvs=<<EOF
SELECT e.encounter_id,e.patient_id,e.encounter_datetime FROM encounter e
INNER JOIN orders ON orders.encounter_id = e.encounter_id 
INNER JOIN drug_order ON drug_order.order_id = orders.order_id
INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id 
INNER JOIN concept_set ON drug.concept_id = concept_set.concept_id AND concept_set = 460
WHERE orders.voided = 0
GROUP BY e.patient_id ,DATE(e.encounter_datetime)
ORDER BY e.patient_id , e.encounter_datetime DESC
EOF

    encounters = Encounter.find_by_sql(all_patient_on_arvs)
    
    count = encounters.length
    puts "Records found: #{count} ..."
    sleep 5
      
    encounters.map do |encounter|
      patient_id = encounter.patient_id
      dispensed_date = encounter.encounter_datetime
      regimen = get_regimen_dispensed(patient_id,dispensed_date)
      dispensed_date = dispensed_date.strftime("%Y-%m-%d %H:%M:%S")

      regimen_concept_id = self.regimen_concept(regimen)
      
ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_historical_regimens (regimen_concept_id,patient_id, encounter_id, dispensed_date,category)
VALUES(#{regimen_concept_id},#{patient_id},#{encounter.encounter_id},'#{dispensed_date}','#{regimen}');
EOF

      puts ".................... #{count -= 1} to go"
    end
    puts ".............. done"
  ensure
    @@indexing = false
    p = GlobalProperty.find_by_property('patient_historical_regimen_indexing')
    p ||= GlobalProperty.create(:property => 'patient_historical_regimen_indexing') 
    p.property_value = @@indexing
    p.save
  end
  
  def self.get_regimen_dispensed(patient_id,dispensed_date)
    start_date = dispensed_date.strftime("%Y-%m-%d 00:00:00")
    end_date = dispensed_date.strftime("%Y-%m-%d 23:59:59")

    drug_ids = DrugOrder.find(:all,:joins =>"
INNER JOIN `orders` ON drug_order.order_id = orders.order_id AND orders.voided = 0
INNER JOIN encounter ON  orders. encounter_id = encounter.encounter_id
AND encounter_datetime >= '#{start_date}' 
AND encounter.encounter_datetime <= '#{end_date}' 
AND encounter.patient_id = #{patient_id}
INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id 
INNER JOIN concept_set ON drug.concept_id = concept_set.concept_id AND concept_set = 460",
    :group =>"drug_order.drug_inventory_id").collect{|d|d.drug_inventory_id}

    DrugRegimenCombination.find_by_sql("
SELECT combination,category,count(*) c 
FROM drug_regimen_combinations d 
INNER JOIN mapping_drug_regimen m ON d.combination = m.id
WHERE drug_id IN(#{drug_ids.join(',')})
GROUP BY combination
HAVING c =  (SELECT count(*) FROM drug_regimen_combinations 
WHERE combination = d.combination)").collect{|r|r.category}.first rescue nil
  end

  def self.regimen_concept(category)
    return 449 if category.blank?
    categories = {"1A" => 450,"1P" => 450,"2A" => 451,"2P" => 451,"3A" => 452,
                  "3P" => 452,"4A" => 458,"4P" => 458,"5A" => 826,"6A" => 827,
                  "7A" => 828,"8A" => 829,"9P" => 453 }
    categories[category]
  end
 
end
