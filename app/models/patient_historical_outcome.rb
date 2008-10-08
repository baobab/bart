# Patient historical outcomes are just a cached version of the patient outcomes.
# Please see PatientOutcome for more details on how outcomes are calculated.
class PatientHistoricalOutcome < ActiveRecord::Base
  set_table_name :patient_historical_outcomes
  belongs_to :patient
  belongs_to :concept
  
  @@index_date = nil
  @@indexing = false
  
  def self.find(*args)
    d = self.index_date
    reindex unless d && d >= Date.today
    super
  end
  
  def self.reset
    self.reindex
  end  
  
private

  def self.index_date
    return @@index_date if @@index_date && @@index_date >= Date.today    
    p = GlobalProperty.find_by_property('patient_historical_outcome_index_date')
    p ||= GlobalProperty.create(:property => 'patient_historical_outcome_index_date') 
    Date.parse(p.property_value) rescue nil    
  end
  
  def self.indexing?
    return @@indexing if @@indexing
    p = GlobalProperty.find_by_property('patient_historical_outcome_indexing')
    p ||= GlobalProperty.create(:property => 'patient_historical_outcome_indexing') 
    p.property_value == 'true' rescue false    
  end  

  def self.reindex
    raise "Sorry I am currently building the historical outcome indexes. Please refresh the page you were trying to load" if self.indexing?    

    @@index_date = Date.today 
    p = GlobalProperty.find_or_create_by_property('patient_historical_outcome_index_date')
    p.property_value = @@index_date
    p.save

    @@indexing = true
    p = GlobalProperty.find_or_create_by_property('patient_historical_outcome_indexing')
    p.property_value = @@indexing
    p.save
    
ActiveRecord::Base.connection.execute <<EOF
DELETE FROM patient_historical_outcomes;
EOF

ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_historical_outcomes (patient_id, outcome_concept_id, outcome_date)
  SELECT patient_id, 
         outcome_concept_id, 
         outcome_date
  FROM patient_outcomes;
EOF

  ensure
    @@indexing = false
    p = GlobalProperty.find_by_property('patient_historical_outcomes_indexing')
    p ||= GlobalProperty.create(:property => 'patient_historical_outcomes_indexing') 
    p.property_value = @@indexing
    p.save
  end
  
end

=begin
CREATE TABLE patient_historical_outcomes (
  `id` int(11) NOT NULL auto_increment,
  `patient_id` int(11) NOT NULL,
  `outcome_concept_id` int(11) NOT NULL,
  `outcome_date` DATE NOT NULL
  PRIMARY KEY  (`id`),
  KEY `patient_id_outcome_concept_id_outcome_date` (`patient_id`, `outcome_concept_id`, `outcome_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
=end
