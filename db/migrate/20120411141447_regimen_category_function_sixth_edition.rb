class RegimenCategoryFunctionSixthEdition < ActiveRecord::Migration
  
  def self.up
ActiveRecord::Base.connection.execute <<EOF
DROP FUNCTION IF EXISTS regimen_category;
EOF

    ActiveRecord::Base.connection.execute <<EOF
CREATE FUNCTION regimen_category(pat_id int, regimen_id int, dispensed_date varchar(10)) RETURNS VARCHAR(2)
DETERMINISTIC                                                                   
BEGIN
DECLARE category VARCHAR(2);                                                               
DECLARE t_class INT;                                                               
DECLARE start_date VARCHAR(20);                                                               
DECLARE end_date VARCHAR(20);                                                               

set start_date = CONCAT(dispensed_date , " 00:00:00");
set end_date = CONCAT(dispensed_date , " 23:59:59");




set t_class = (SELECT MIN(therapy_class) FROM drug_order INNER JOIN `orders` ON drug_order.order_id = orders.order_id INNER JOIN encounter ON  orders.encounter_id = encounter.encounter_id INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id INNER JOIN concept_set ON drug.concept_id = concept_set.concept_id AND concept_set = 460 WHERE encounter.patient_id = pat_id AND orders.voided = 0 AND encounter_datetime >= start_date AND encounter.encounter_datetime <= end_date LIMIT 1);

if regimen_id = 450 and t_class = 1 then set category = "1P";                                    
elseif regimen_id = 450 and t_class = 2 then set category = "1A";                                    
elseif regimen_id = 451 and t_class = 1 then set category = "2P";                                    
elseif regimen_id = 451 and t_class = 2 then set category = "2A";                                    
elseif regimen_id = 452 and t_class = 1 then set category = "3P";                                    
elseif regimen_id = 452 and t_class = 2 then set category = "3A";                                    
elseif regimen_id = 458 and t_class = 1 then set category = "4P";                                    
elseif regimen_id = 458 and t_class = 2 then set category = "4A";                                    
elseif regimen_id = 826 then set category = "5A";                                    
elseif regimen_id = 827 then set category = "6A";                                    
elseif regimen_id = 828 then set category = "7A";                                    
elseif regimen_id = 829 then set category = "8A";                                    
elseif regimen_id = 830 then set category = "9P";                                    
end if;   

RETURN category;                                                                     
END;
EOF
  end

  def self.down
    ActiveRecord::Base.connection.execute <<EOF
DROP FUNCTION IF EXISTS `regimen_category`;
EOF

    ActiveRecord::Base.connection.execute <<EOF
CREATE FUNCTION regimen_category(pat_id int, regimen_id int, dispensed_date varchar(10)) RETURNS VARCHAR(2) 
DETERMINISTIC                                                                   
BEGIN
DECLARE pat_age INT;                                                        
DECLARE category VARCHAR(2);                                                               
DECLARE birthdate_date VARCHAR(10);                                                               
DECLARE birthdate_created VARCHAR(10);                                                               
DECLARE age_estimated INT;                                                        

DECLARE current_weight DOUBLE; 
DECLARE weight_then DOUBLE;
DECLARE weight DOUBLE;                                                          
DECLARE weight_concept_id INT;                                                        

set birthdate_date = (SELECT birthdate FROM patient WHERE patient_id = pat_id);
set age_estimated = (SELECT birthdate_estimated FROM patient WHERE patient_id = pat_id);
set birthdate_created = (SELECT DATE(date_created) FROM patient WHERE patient_id = pat_id);
set pat_age = (SELECT age(birthdate_date,dispensed_date,birthdate_created,age_estimated));

set weight_concept_id = (SELECT concept_id FROM concept WHERE name = "Weight" AND retired = 0 LIMIT 1);
set weight_then = (SELECT value_numeric FROM obs WHERE voided = 0 AND patient_id = pat_id AND concept_id = weight_concept_id AND DATE(obs_datetime) <= dispensed_date ORDER BY obs_datetime DESC LIMIT 1);
set weight = (SELECT value_numeric FROM obs WHERE voided = 0 AND patient_id = pat_id AND concept_id = weight_concept_id ORDER BY obs_datetime DESC LIMIT 1);

if weight_then > 0 then set current_weight = weight_then;  
elseif weight > 0 then set current_weight = weight;  
end if;

if regimen_id = 450 and current_weight < 30 then set category = "1P";                                    
elseif regimen_id = 450 and current_weight >= 30 then set category = "1A";                                    
elseif regimen_id = 451 and current_weight < 30 then set category = "2P";                                    
elseif regimen_id = 451 and current_weight >= 30 then set category = "2A";                                    
elseif regimen_id = 452 and current_weight < 40 then set category = "3P";                                    
elseif regimen_id = 452 and current_weight >= 40 then set category = "3A";                                    
elseif regimen_id = 458 and current_weight < 40 then set category = "4P";                                    
elseif regimen_id = 458 and current_weight >= 40 then set category = "4A";                                    
elseif regimen_id = 826 then set category = "5A";                                    
elseif regimen_id = 827 then set category = "6A";                                    
elseif regimen_id = 828 then set category = "7A";                                    
elseif regimen_id = 829 then set category = "8A";                                    
elseif regimen_id = 453 then set category = "9P";                                    
elseif regimen_id = 450 and pat_age <= 14 then set category = "1P";                                    
elseif regimen_id = 450 and pat_age > 14 then set category = "1A";                                    
elseif regimen_id = 451 and pat_age <= 14 then set category = "2P";                                    
elseif regimen_id = 451 and pat_age > 14 then set category = "2A";                                    
elseif regimen_id = 452 and pat_age <= 14 then set category = "3P";                                    
elseif regimen_id = 452 and pat_age > 14  then set category = "3A";                                    
elseif regimen_id = 458 and pat_age <= 14 then set category = "4P";                                    
elseif regimen_id = 458 and pat_age > 14  then set category = "4A";                                    
elseif regimen_id = 826 then set category = "5A";                                    
elseif regimen_id = 827 then set category = "6A";                                    
elseif regimen_id = 828 then set category = "7A";                                    
elseif regimen_id = 829 then set category = "8A";                                    
elseif regimen_id = 453 then set category = "9P";      
elseif regimen_id = 450 then set category = "1A";                                    
elseif regimen_id = 451 then set category = "2A";                                    
elseif regimen_id = 452 then set category = "3A";                                    
elseif regimen_id = 458 then set category = "4A";                                    
end if;   

RETURN category;                                                                     
END;
EOF
  end
end
