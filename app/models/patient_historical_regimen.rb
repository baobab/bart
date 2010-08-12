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

ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_historical_regimens (regimen_concept_id, patient_id, encounter_id, dispensed_date)
  SELECT regimen_concept_id,
         patient_id,
         encounter_id,
         dispensed_date
  FROM patient_regimens;
EOF
=begin
    # Add Non-Standard Regimens
ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_historical_regimens
  (regimen_concept_id, patient_id, encounter_id, dispensed_date)
SELECT 449, pri.patient_id, pri.encounter_id, pri.dispensed_date
  FROM patient_regimen_ingredients pri
  WHERE NOT EXISTS (
    SELECT * FROM patient_historical_regimens phr
    WHERE phr.encounter_id = pri.encounter_id
    )
  GROUP BY pri.patient_id, pri.encounter_id
EOF
=end
  ensure
    @@indexing = false
    p = GlobalProperty.find_by_property('patient_historical_regimen_indexing')
    p ||= GlobalProperty.create(:property => 'patient_historical_regimen_indexing') 
    p.property_value = @@indexing
    p.save
  end
  
end
