class RegimenCategoryFunctionRevisedSecondEdition < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
DROP FUNCTION IF EXISTS regimen_category;
EOF

    ActiveRecord::Base.connection.execute <<EOF
CREATE FUNCTION regimen_category(pat_id int, regimen_id int, dispensed_date varchar(10)) RETURNS VARCHAR(2) 
DETERMINISTIC                                                                   
BEGIN
DECLARE pat_age INT;                                                        
DECLARE category VARCHAR(2);                                                               


DECLARE current_weight DOUBLE;                                                           
DECLARE weight_concept_id INT;                                                        

set weight_concept_id = (SELECT concept_id FROM concept WHERE name = "Weight" AND pat_id AND retired = 0 LIMIT 1);
set current_weight = (SELECT value_numeric FROM obs WHERE voided = 0 AND patient_id = pat_id AND concept_id = weight_concept_id AND DATE(obs_datetime) <= dispensed_date LIMIT 1);

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
end if;   

RETURN category;                                                                     
END;
EOF
  end

  def self.down
    ActiveRecord::Base.connection.execute <<EOF
DROP FUNCTION IF EXISTS `regimen_category`;
EOF
  end
end
