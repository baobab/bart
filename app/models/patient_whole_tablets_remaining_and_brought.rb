class PatientWholeTabletsRemainingAndBrought < ActiveRecord::Base
  set_table_name :patient_whole_tablets_remaining_and_brought
  belongs_to :patient
  belongs_to :drug

  
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
    p = GlobalProperty.find_by_property('patient_whole_tablets_remaining_and_brought_index_date')
    p ||= GlobalProperty.create(:property => 'patient_whole_tablets_remaining_and_brought_index_date') 
    Date.parse(p.property_value) rescue nil    
  end
  
  def self.indexing?
    return @@indexing if @@indexing
    p = GlobalProperty.find_by_property('patient_whole_tablets_remaining_and_brought_indexing')
    p ||= GlobalProperty.create(:property => 'patient_whole_tablets_remaining_and_brought_indexing') 
    p.property_value == 'true' rescue false    
  end  

  def self.reindex
    raise "Sorry I am currently building the drug and prescription indexes. Please refresh the page you were trying to load" if self.indexing?    

    @@index_date = Date.today 
    p = GlobalProperty.find_or_create_by_property('patient_whole_tablets_remaining_and_brought_index_date')
    p.property_value = @@index_date
    p.save

    @@indexing = true
    p = GlobalProperty.find_or_create_by_property('patient_whole_tablets_remaining_and_brought_indexing')
    p.property_value = @@indexing
    p.save
    
ActiveRecord::Base.connection.execute <<EOF
    DELETE FROM patient_whole_tablets_remaining_and_brought;
EOF

ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_whole_tablets_remaining_and_brought (patient_id, drug_id, visit_date, total_remaining)
  SELECT patient_id, value_drug, DATE(obs_datetime) as visit_date, value_numeric 
  FROM obs
  WHERE obs.concept_id = 363 AND obs.voided = 0
  GROUP BY patient_id, value_drug, visit_date
  ORDER BY obs_id DESC;
EOF

  ensure
    @@indexing = false
    p = GlobalProperty.find_by_property('patient_whole_tablets_remaining_and_brought_indexing')
    p ||= GlobalProperty.create(:property => 'patient_whole_tablets_remaining_and_brought_indexing') 
    p.property_value = @@indexing
    p.save
  end
  
end

=begin
DROP TABLE IF EXISTS patient_whole_tablets_remaining_and_brought;
CREATE TABLE patient_whole_tablets_remaining_and_brought (
  `id` int(11) NOT NULL auto_increment,
  `patient_id` int(11) NOT NULL,
  `drug_id` int(11) NOT NULL,
  `visit_date` DATE NOT NULL,
  `total_remaining` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `patient_id_drug_id_presciption_date` (`patient_id`, `drug_id`, `visit_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO patient_whole_tablets_remaining_and_brought (patient_id, drug_id, visit_date, total_remaining)
  SELECT patient_id, value_drug, DATE(obs_datetime) as visit_date, value_numeric 
  FROM obs
  WHERE obs.concept_id = 363 AND obs.voided = 0
  GROUP BY patient_id, value_drug, visit_date
  ORDER BY obs_id DESC;
=end