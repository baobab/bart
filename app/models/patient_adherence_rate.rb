# Patient Adherence Rates contains calculated adherence values for each patient's drug and visit date
#
# In order for this calculation to work you must have access to the dispensation
# and prescription information. This is accessed though the 
# <tt>PatientDispensationAndPrescription</tt> model (which is implemented as a
# MYSQL view). 
# 
# Since calculation of adherence requires looking up the previous visit before the pill count,
# using a MySQL View would be very inefficient. So a temporary table is created to store PatientDispensationAndPrescription
# entries.
#
# = Notes
#
# Because calculating the date values takes a considerable amount of time this
# table cannot currently be implemented as a MYSQL view. To get around this,
# the contents of the table are refreshed once per day. Ideally this would be
# optimized.
class PatientAdherenceRate < ActiveRecord::Base
  set_table_name :patient_adherence_rates
  belongs_to :patient
  belongs_to :drug
  
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
    p = GlobalProperty.find_by_property('patient_adherence_rate_index_date')
    p ||= GlobalProperty.create(:property => 'patient_adherence_rate_index_date') 
    Date.parse(p.property_value) rescue nil    
  end
  
  def self.indexing?
    return @@indexing if @@indexing
    p = GlobalProperty.find_by_property('patient_adherence_rate_indexing')
    p ||= GlobalProperty.create(:property => 'patient_adherence_rate_indexing') 
    p.property_value == 'true' rescue false    
  end  

  def self.reindex
    raise "Sorry I am currently building the adherence rate indexes. Please refresh the page you were trying to load" if self.indexing?    

    @@index_date = Date.today 
    p = GlobalProperty.find_or_create_by_property('patient_adherence_rate_index_date')
    p.property_value = @@index_date
    p.save

    @@indexing = true
    p = GlobalProperty.find_or_create_by_property('patient_adherence_rate_indexing')
    p.property_value = @@indexing
    p.save
    
    ActiveRecord::Base.connection.execute <<EOF
      TRUNCATE TABLE patient_adherence_rates;
EOF
    ActiveRecord::Base.connection.execute <<EOF
      DROP TABLE IF EXISTS tmp_patient_dispensations_and_prescriptions;
EOF

    ActiveRecord::Base.connection.execute <<EOF
      CREATE TABLE `tmp_patient_dispensations_and_prescriptions` (
        `patient_id` int(11) NOT NULL default '0',
        `encounter_id` int(11) NOT NULL default '0',
        `visit_date` DATE,
        `drug_id` int(11) NOT  NULL default '0',
        `total_dispensed` decimal(32,0),
        `total_remaining` int(11),
        `daily_consumption` int(11),
        PRIMARY KEY(patient_id,encounter_id,visit_date,drug_id)
      ) ENGINE=MyISAM DEFAULT CHARSET=latin1;
EOF

    ActiveRecord::Base.connection.execute <<EOF
      INSERT INTO tmp_patient_dispensations_and_prescriptions  (
        SELECT * FROM patient_dispensations_and_prescriptions
      );
EOF

    ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_adherence_rates (patient_id,visit_date,drug_id,expected_remaining,adherence_rate) 
SELECT t1.patient_id,t1.visit_date,t1.drug_id, 
SUM(t2.total_dispensed) +  IF(t3.registration_date=t1.previous_visit_date,IFNULL(SUM(t2.total_remaining),0),SUM(t2.total_remaining)) - (t2.daily_consumption * DATEDIFF(t1.visit_date, t2.visit_date)) AS expexted_remaining,
adherence_calculator(t1.total_remaining,(t2.total_dispensed + t2.total_remaining),t2.daily_consumption,t1.visit_date,t2.visit_date) AS adherence_rate
FROM patient_whole_tablets_remaining_and_brought t1
INNER JOIN tmp_patient_dispensations_and_prescriptions t2 ON t1.patient_id = t2.patient_id AND
t1.drug_id=t2.drug_id AND t1.previous_visit_date=t2.visit_date
INNER JOIN patient_registration_dates t3 ON t3.patient_id=t1.patient_id
GROUP BY t1.patient_id, t1.visit_date, t1.drug_id
EOF
=begin
    ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_adherence_rates (patient_id,visit_date,drug_id,expected_remaining,adherence_rate) 
SELECT t1.patient_id,t1.visit_date,t1.drug_id, 
SUM(t2.total_dispensed) +  IF(t3.registration_date=t1.previous_visit_date,IFNULL(SUM(t2.total_remaining),0),SUM(t2.total_remaining)) - (t2.daily_consumption * DATEDIFF(t1.visit_date, t2.visit_date)) AS expexted_remaining,
(SELECT 100*(SUM(t2.total_dispensed)+SUM(t2.total_remaining)-t1.total_remaining)/((SUM(t2.total_dispensed)+       SUM(t2.total_remaining) - (SUM(t2.total_dispensed)+ SUM(t2.total_remaining) - (t2.daily_consumption * DATEDIFF(t1.visit_date, t2.visit_date)))))) AS adherence_rate
FROM patient_whole_tablets_remaining_and_brought t1
INNER JOIN tmp_patient_dispensations_and_prescriptions t2 ON t1.patient_id = t2.patient_id AND
t1.drug_id=t2.drug_id AND t1.previous_visit_date=t2.visit_date
INNER JOIN patient_registration_dates t3 ON t3.patient_id=t1.patient_id
GROUP BY t1.patient_id, t1.visit_date, t1.drug_id
EOF
=end
  ensure
    @@indexing = false
    p = GlobalProperty.find_by_property('patient_adherence_rate_indexing')
    p ||= GlobalProperty.create(:property => 'patient_adherence_rate_indexing') 
    p.property_value = @@indexing
    p.save
  end
  
end

=begin
DROP TABLE IF EXISTS patient_adherence_rates;
CREATE TABLE `patient_adherence_rates` (
  `id` int(11) NOT NULL auto_increment,
  `patient_id` int(11) NOT NULL default '0',
  `visit_date` DATE,
  `drug_id` int(11) NOT  NULL default '0',
  `adherence_rate` int(11),
  PRIMARY KEY(id),
  UNIQUE KEY `patient_visit_drug ON patient_adherence_rates` (`patient_id`,`visit_date`,`drug_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `tmp_patient_dispensations_and_prescriptions` (
        `patient_id` int(11) NOT NULL default '0',
        `encounter_id` int(11) NOT NULL default '0',
        `visit_date` DATE,
        `drug_id` int(11) NOT  NULL default '0',
        `total_dispensed` decimal(32,0),
        `total_remaining` int(11),
        `daily_consumption` int(11),
        PRIMARY KEY(patient_id,encounter_id,visit_date,drug_id)
      ) ENGINE=MyISAM DEFAULT CHARSET=latin1;

INSERT INTO tmp_patient_dispensations_and_prescriptions  (
        SELECT * FROM patient_dispensations_and_prescriptions
      );

 INSERT INTO patient_adherence_rates (patient_id,visit_date,drug_id,adherence_rate) 
        SELECT t1.patient_id, t1.visit_date, t1.drug_id,
          (SELECT 100*(SUM(total_dispensed)+SUM(total_remaining)-t1.total_remaining)/
          ((SUM(total_dispensed)+SUM(total_remaining)) - (SUM(total_dispensed)+SUM(total_remaining) - (daily_consumption * DATEDIFF(t1.visit_date, t2.visit_date))))
           FROM tmp_patient_dispensations_and_prescriptions t2 
           WHERE t2.patient_id = t1.patient_id AND t2.drug_id = t1.drug_id AND t2.visit_date < t1.visit_date 
           GROUP BY t2.patient_id,t2.visit_date DESC LIMIT 1) AS adherence_rate 
        FROM tmp_patient_dispensations_and_prescriptions t1
        GROUP BY patient_id, visit_date, drug_id;     

=end
