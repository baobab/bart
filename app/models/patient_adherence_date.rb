# Patient Adherence Dates are useful in determining the outcome of the patient.
# In order to determine if a patient is adherent and/or a defaulter, you need
# to calculate the date that the patient will run out of drugs and then 
# add two months to that date.
#
# In order for this calculation to work you must have access to the dispensation
# and prescription information. This is accessed though the 
# <tt>PatientDispensationAndPrescription</tt> model (which is implemented as a
# MYSQL view). 
#
# = Notes
#
# Because calculating the date values takes a considerable amount of time this
# table cannot currently be implemented as a MYSQL view. To get around this,
# the contents of the table are refreshed once per day. Ideally this would be
# optimized.
class PatientAdherenceDate < ActiveRecord::Base
  set_table_name :patient_adherence_dates
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
    p = GlobalProperty.find_by_property('patient_adherence_index_date')
    p ||= GlobalProperty.create(:property => 'patient_adherence_index_date') 
    Date.parse(p.property_value) rescue nil    
  end
  
  def self.indexing?
    return @@indexing if @@indexing
    p = GlobalProperty.find_by_property('patient_adherence_indexing')
    p ||= GlobalProperty.create(:property => 'patient_adherence_indexing') 
    p.property_value == 'true' rescue false    
  end  

  def self.reindex
    raise "Sorry I am currently building the adherence indexes. Please refresh the page you were trying to load" if self.indexing?    

    @@index_date = Date.today 
    p = GlobalProperty.find_or_create_by_property('patient_adherence_index_date')
    p.property_value = @@index_date
    p.save

    @@indexing = true
    p = GlobalProperty.find_or_create_by_property('patient_adherence_indexing')
    p.property_value = @@indexing
    p.save
    
ActiveRecord::Base.connection.execute <<EOF
DELETE FROM patient_adherence_dates;
EOF

# 28 is the default number of days if we don't know the prescription or total tablets remaining (fallback to MOH paper approach)
ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_adherence_dates (patient_id, drug_id, visit_date, drugs_run_out_date, default_date)
  SELECT patient_id, 
         drug_id, 
         visit_date, 
         ADDDATE(visit_date, INTERVAL IFNULL(((total_remaining + total_dispensed) / daily_consumption), 28) DAY) as drugs_run_out_date,
         ADDDATE(visit_date, INTERVAL IFNULL(((total_remaining + total_dispensed) / daily_consumption), 28) + 56 DAY) as default_date
  FROM patient_dispensations_and_prescriptions;
EOF

  ensure
    @@indexing = false
    p = GlobalProperty.find_by_property('patient_adherence_indexing')
    p ||= GlobalProperty.create(:property => 'patient_adherence_indexing') 
    p.property_value = @@indexing
    p.save
  end
  
end

=begin
DROP TABLE IF EXISTS patient_adherence_dates;
CREATE TABLE patient_adherence_dates (
  `id` int(11) NOT NULL auto_increment,
  `patient_id` int(11) NOT NULL,
  `drug_id` int(11) NOT NULL,
  `visit_date` DATE NOT NULL,
  `drugs_run_out_date` DATE NOT NULL,
  `default_date` DATE NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `patient_id_visit_date_default_date` (`patient_id`, `visit_date`, `default_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- 28 is the default number of days if we don't know the prescription or total tablets remaining (fallback to MOH paper approach)
DELETE FROM patient_adherence_dates;
INSERT INTO patient_adherence_dates (patient_id, drug_id, visit_date, drugs_run_out_date, default_date)
  SELECT patient_id, 
         drug_id, 
         visit_date, 
         ADDDATE(visit_date, INTERVAL IFNULL(((total_remaining + total_dispensed) / daily_consumption), 28) DAY) as drugs_run_out_date,
         ADDDATE(visit_date, INTERVAL IFNULL(((total_remaining + total_dispensed) / daily_consumption), 28) + 56 DAY) as default_date
  FROM patient_dispensations_and_prescriptions;

=end