# PatientPrescriptionTotal is a table will collect all of the prescription 
# information for a particular drug and particular visit. For example, it is
# common that a patient will be prescribed 1 Triomune in the Morning and 1
# Triomune in the evening. In order to calculate the daily consumption these
# values need to be added together. Each specific prescription will have its
# own daily consumption calculated (this is handled by the
# <tt>PatientPrescription</tt> model) which will combine to form the daily
# consumption for the drug.
#
# = Usage
#
# Knowing the complete daily consumption is an integral part of figuring out
# how many drugs should be dispensed for the time period specified. Additionally,
# this information is used to calculate <tt>PatientAdherenceDate</tt> values
# as you need to know how many tablets (or other forms or drug) the patient
# was told to consume each day to know if they are adherent based on the 
# remaining pill count.
#
# = Notes
#
# Because grouping and summing all prescription information takes a considerable
# amount of time, this table cannot currently be implemented as a MYSQL view. 
# To get around this, the contents of the table are refreshed once per day. 
# Ideally this would be optimized. Additionally, the added indexes on the table
# simplify later joins.
class PatientPrescriptionTotal < ActiveRecord::Base
  set_table_name :patient_prescription_totals
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
    p = GlobalProperty.find_by_property('patient_prescription_total_index_date')
    p ||= GlobalProperty.create(:property => 'patient_prescription_total_index_date') 
    Date.parse(p.property_value) rescue nil    
  end
  
  def self.indexing?
    return @@indexing if @@indexing
    p = GlobalProperty.find_by_property('patient_prescription_total_indexing')
    p ||= GlobalProperty.create(:property => 'patient_prescription_total_indexing') 
    p.property_value == 'true' rescue false    
  end  

  def self.reindex
    raise "Sorry I am currently building the drug and prescription indexes. Please refresh the page you were trying to load" if self.indexing?    

    @@index_date = Date.today 
    p = GlobalProperty.find_or_create_by_property('patient_prescription_total_index_date')
    p.property_value = @@index_date
    p.save

    @@indexing = true
    p = GlobalProperty.find_or_create_by_property('patient_prescription_total_indexing')
    p.property_value = @@indexing
    p.save
    
ActiveRecord::Base.connection.execute <<EOF
    DELETE FROM patient_prescription_totals;
EOF

ActiveRecord::Base.connection.execute <<EOF
    INSERT INTO patient_prescription_totals (patient_id, drug_id, prescription_date, daily_consumption)
      SELECT patient_id, drug_id, DATE(prescription_datetime) as prescription_date, SUM(daily_consumption) AS daily_consumption 
      FROM patient_prescriptions
      GROUP BY patient_id, drug_id, prescription_date;  
EOF

  ensure
    @@indexing = false
    p = GlobalProperty.find_by_property('patient_prescription_total_indexing')
    p ||= GlobalProperty.create(:property => 'patient_prescription_total_indexing') 
    p.property_value = @@indexing
    p.save
  end
  
end

=begin
DROP TABLE IF EXISTS patient_prescription_totals;
CREATE TABLE patient_prescription_totals (
  `id` int(11) NOT NULL auto_increment,
  `patient_id` int(11) NOT NULL,
  `drug_id` int(11) NOT NULL,
  `prescription_date` DATE NOT NULL,
  `daily_consumption` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `patient_id_drug_id_presciption_date` (`patient_id`, `drug_id`, `prescription_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
=end