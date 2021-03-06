# Patient historical outcomes are just a cached version of the patient outcomes.
# Please see PatientOutcome for more details on how outcomes are calculated.
class PatientHistoricalOutcome < ActiveRecord::Base
  set_table_name :patient_historical_outcomes
  belongs_to :patient
  belongs_to :concept, :foreign_key => 'outcome_concept_id'
  
  @@index_date = nil
  @@indexing = false
  
  def self.find(*args)
#    d = self.index_date
#    reindex unless d && d >= Date.today
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

#..............................................................................
    #Will revert to the old code soon
    patients = Patient.find(:all,:joins => 'INNER JOIN encounter e ON patient.patient_id = e.patient_id
      INNER JOIN orders ON orders.encounter_id = e.encounter_id',
      :conditions => ["orders.voided = 0 AND orders.order_type_id = 1"],
      :group => "patient.patient_id")
    
    count = patients.length

    (patients || []).each do |patient|
      patient.reset_outcomes
      puts "#{count-= 1} patient(s) to go ...."
    end

    return 
#..............................................................................

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

# Update old Stop Concepts to ART Stop
ActiveRecord::Base.connection.execute <<EOF
UPDATE patient_historical_outcomes
  SET outcome_concept_id = 386
  WHERE outcome_concept_id = 323;
EOF

#Update to outcome to defaulter all patients with registration date but no outcome
ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_historical_outcomes(patient_id,outcome_concept_id,outcome_date) 
  SELECT patient_id, 373, registration_date FROM patient_registration_dates a 
  WHERE NOT EXISTS(SELECT DISTINCT(patient_id) 
  FROM patient_historical_outcomes b where a.patient_id = b.patient_id) 
EOF
  ensure
    @@indexing = false
    p = GlobalProperty.find_by_property('patient_historical_outcome_indexing')
    p ||= GlobalProperty.create(:property => 'patient_historical_outcome_indexing') 
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
