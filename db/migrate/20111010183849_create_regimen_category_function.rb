class CreateRegimenCategoryFunction < ActiveRecord::Migration
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


DECLARE birthdate VARCHAR(10);                                                               
DECLARE birthdate_estimated INT;                                                               
DECLARE date_created VARCHAR(10);                                                               

set birthdate = (SELECT LEFT(p.birthdate,10) FROM patient p WHERE p.patient_id = pat_id);
set birthdate_estimated = (SELECT p.birthdate_estimated FROM patient p WHERE p.patient_id = pat_id);
set date_created = (SELECT LEFT(p.date_created,10) FROM patient p WHERE p.patient_id = pat_id);

set pat_age = (SELECT age(birthdate,dispensed_date,date_created,birthdate_estimated));

if pat_age < 15 then set category = "P";                                    
elseif pat_age > 14 then set category = "A";                            
end if;   

if regimen_id = 450 and category = "P" then set category = "P1";                                    
elseif regimen_id = 450 and category = "A" then set category = "A1";                                    
elseif regimen_id = 451 and category = "P" then set category = "P2";                                    
elseif regimen_id = 451 and category = "A" then set category = "A2";    
elseif regimen_id = 452 and category = "A" then set category = "A3";                                    
elseif regimen_id = 452 and category = "P" then set category = "P3";                                    
elseif regimen_id = 458 and category = "P" then set category = "P4";                                    
elseif regimen_id = 458 and category = "A" then set category = "A4";                                    
elseif regimen_id = 826 and category = "P" then set category = "P5";                                    
elseif regimen_id = 826 and category = "A" then set category = "A5";                                    
elseif regimen_id = 827 and category = "P" then set category = "P6";                                    
elseif regimen_id = 827 and category = "A" then set category = "A6";                                    
elseif regimen_id = 828 and category = "P" then set category = "P7";                                    
elseif regimen_id = 828 and category = "A" then set category = "A7";                                    
elseif regimen_id = 829 and category = "P" then set category = "P8";                                    
elseif regimen_id = 829 and category = "A" then set category = "A8";                                    
elseif regimen_id = 453 and category = "A" then set category = "A9";    
elseif regimen_id = 453 and category = "P" then set category = "P9";                                    
else set category = "Nn";                                    
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
