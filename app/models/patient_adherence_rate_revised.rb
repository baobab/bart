class PatientAdherenceRateRevised < ActiveRecord::Base
  set_table_name :patient_adherence_rates
  belongs_to :patient
  belongs_to :drug
  
  def self.reset
    self.reindex
  end  

  private

  def self.reindex
    ActiveRecord::Base.connection.execute <<EOF
      DROP TABLE IF EXISTS tmp_patient_dispensations_and_prescriptions_calculations;
EOF

    ActiveRecord::Base.connection.execute <<EOF
      CREATE TABLE `tmp_patient_dispensations_and_prescriptions_calculations` (
        `id` INT NOT NULL AUTO_INCREMENT ,
        `patient_id` int(11) NOT NULL default '0',
        `visit_date` DATETIME,
        `drug_id` int(11) NOT  NULL default '0',
        `total_dispensed` decimal(32,0),
        `total_remaining` int(11),
        `daily_consumption` int(11),
        PRIMARY KEY(id)
      ) ENGINE=MyISAM DEFAULT CHARSET=latin1;
EOF

    ActiveRecord::Base.connection.execute <<EOF
      INSERT INTO tmp_patient_dispensations_and_prescriptions_calculations (patient_id,drug_id,total_dispensed,visit_date) 
      SELECT e.patient_id,drug_inventory_id,SUM(quantity),encounter_datetime FROM encounter e 
      INNER JOIN orders ON e.encounter_id = orders.encounter_id 
      INNER JOIN drug_order d ON d.order_id = orders.order_id WHERE voided=0 GROUP BY drug_inventory_id,DATE(encounter_datetime);
EOF


    ActiveRecord::Base.connection.execute <<EOF
      UPDATE tmp_patient_dispensations_and_prescriptions_calculations t1 
      INNER JOIN obs t2 ON t1.patient_id = t2.patient_id
      SET t1.total_remaining = (SELECT SUM(value_numeric) FROM obs WHERE concept_id=363 AND voided=0
      AND obs.obs_id = t2.obs_id GROUP BY patient_id,value_drug,DATE(obs_datetime))
      WHERE t1.patient_id = t2.patient_id AND t1.visit_date BETWEEN 
      DATE_FORMAT(t2.obs_datetime, '%Y/%m/%d 00:00:00')
      AND DATE_FORMAT(t2.obs_datetime, '%Y/%m/%d 23:59:59') AND t2.concept_id=363;
EOF

    ActiveRecord::Base.connection.execute <<EOF
      UPDATE tmp_patient_dispensations_and_prescriptions_calculations t1        
      INNER JOIN obs t2 ON t1.patient_id = t2.patient_id                        
      SET t1.daily_consumption = (                                              
      SELECT SUM(obs.value_numeric) FROM obs                                    
      WHERE obs.concept_id=375 AND obs.voided=0
      AND obs.patient_id=t2.patient_id
      AND obs.value_drug = t2.value_drug     
      GROUP BY obs.patient_id,obs.value_drug,DATE(obs.obs_datetime) LIMIT 1            
      )                                                                         
      WHERE t1.patient_id = t2.patient_id AND t1.visit_date BETWEEN             
      DATE_FORMAT(t2.obs_datetime, '%Y/%m/%d 00:00:00')                         
      AND DATE_FORMAT(t2.obs_datetime, '%Y/%m/%d 23:59:59') AND t2.concept_id=375;
EOF




end




end

