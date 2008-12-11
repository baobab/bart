class AddRegimens < ActiveRecord::Migration
  def self.up
# regimen_ingredients is a VIEW that attempts
# 3 == Give drugs
# 18 == Regimen
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_regimen_ingredients; 
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_regimen_ingredients; 
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_regimen_ingredients (ingredient_concept_id, regimen_concept_id, patient_id, encounter_id, dispensed_date) AS
  SELECT 
    regimen_ingredient.ingredient_id as ingredient_concept_id,
    regimen_ingredient.concept_id as regimen_concept_id,
    encounter.patient_id as patient_id, 
    encounter.encounter_id as encounter_id, 
    encounter.encounter_datetime as dispensed_date
  FROM encounter
  INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
  INNER JOIN drug_order ON drug_order.order_id = orders.order_id
  INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
  INNER JOIN drug_ingredient as dispensed_ingredient ON drug.concept_id = dispensed_ingredient.concept_id
  INNER JOIN drug_ingredient as regimen_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id 
  INNER JOIN concept as regimen_concept ON regimen_ingredient.concept_id = regimen_concept.concept_id 
  WHERE encounter.encounter_type = 3 AND regimen_concept.class_id = 18 AND orders.voided = 0
  GROUP BY encounter.encounter_id, regimen_ingredient.concept_id, regimen_ingredient.ingredient_id;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_regimens;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_regimens;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_regimens (regimen_concept_id, patient_id, encounter_id, dispensed_date) AS
  SELECT patient_regimen_ingredients.regimen_concept_id as regiment_concept_id,
         patient_regimen_ingredients.patient_id as patient_id,
         patient_regimen_ingredients.encounter_id as encounter_id, 
         patient_regimen_ingredients.dispensed_date as dispensed_date        
  FROM patient_regimen_ingredients
  GROUP BY patient_regimen_ingredients.encounter_id, patient_regimen_ingredients.regimen_concept_id
  HAVING count(*) = (SELECT count(*) FROM drug_ingredient WHERE drug_ingredient.concept_id = patient_regimen_ingredients.regimen_concept_id); 
EOF

# Count all of the patients whose first 450 regimen disensation happened in the specified period
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_first_line_regimen_dispensations;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS patient_first_line_regimen_dispensations;
EOF

ActiveRecord::Base.connection.execute <<EOF
CREATE VIEW patient_first_line_regimen_dispensations (patient_id, encounter_id, dispensed_date) AS
  SELECT encounter.patient_id, encounter.encounter_id, encounter.encounter_datetime
  FROM encounter 
  WHERE encounter.encounter_type = 3 AND NOT EXISTS (
    SELECT * FROM orders 
    INNER JOIN drug_order ON drug_order.order_id = orders.order_id
    INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
    INNER JOIN drug_ingredient as dispensed_ingredient ON drug.concept_id = dispensed_ingredient.concept_id
    LEFT JOIN drug_ingredient as regimen_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id AND regimen_ingredient.concept_id IN (450)
    WHERE orders.encounter_id = encounter.encounter_id AND orders.voided = 0 AND dispensed_ingredient.concept_id IS NULL
    GROUP BY encounter.encounter_id, regimen_ingredient.ingredient_id);
EOF
  end

  def self.down
ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_regimen_ingredients;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_regimens;
EOF

ActiveRecord::Base.connection.execute <<EOF
DROP VIEW IF EXISTS patient_first_line_regimen_dispensations;
EOF
  end
end
