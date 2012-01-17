class RegimenCategoryFunction < ActiveRecord::Migration
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

if regimen_id = 453 then set category = "P";                                    
elseif regimen_id = 826 then set category = "A";                                    
elseif regimen_id = 827 then set category = "A";                                    
elseif regimen_id = 828 then set category = "A";                                    
elseif regimen_id = 829 then set category = "A";                                    
elseif pat_age < 15 then set category = "P";                            
elseif pat_age > 14 then set category = "A";                            
end if;   

if regimen_id = 450 and category = "P" then set category = "1P";                                    
elseif regimen_id = 450 and category = "A" then set category = "1A";                                    
elseif regimen_id = 451 and category = "P" then set category = "2P";                                    
elseif regimen_id = 451 and category = "A" then set category = "2A";    
elseif regimen_id = 452 and category = "A" then set category = "3A";                                    
elseif regimen_id = 452 and category = "P" then set category = "3P";                                    
elseif regimen_id = 458 and category = "P" then set category = "4P";                                    
elseif regimen_id = 458 and category = "A" then set category = "4A";
elseif regimen_id = 826 and category = "P" then set category = "5P";                                    
elseif regimen_id = 826 and category = "A" then set category = "5A";                                    
elseif regimen_id = 827 and category = "P" then set category = "6P";                                    
elseif regimen_id = 827 and category = "A" then set category = "6A";                                    
elseif regimen_id = 828 and category = "P" then set category = "7P";                                    
elseif regimen_id = 828 and category = "A" then set category = "7A";                                    
elseif regimen_id = 829 and category = "P" then set category = "8P";                                    
elseif regimen_id = 829 and category = "A" then set category = "8A";
elseif regimen_id = 453 and category = "A" then set category = "9A";    
elseif regimen_id = 453 and category = "P" then set category = "9P";                                    
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
