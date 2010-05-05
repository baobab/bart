class DrugFirstDispensedDate < ActiveRecord::Migration
  def self.up

    ActiveRecord::Base.connection.execute <<EOF
DROP FUNCTION IF EXISTS drug_first_dispensed_date;
EOF

    ActiveRecord::Base.connection.execute <<EOF
CREATE FUNCTION drug_first_dispensed_date(pat_id int,drugid int) RETURNS VARCHAR(10) 
DETERMINISTIC
BEGIN
DECLARE dispensed_date VARCHAR(10);

set dispensed_date = (SELECT DATE(e.encounter_datetime) FROM encounter e INNER JOIN orders ON orders.encounter_id=e.encounter_id AND orders.voided=0 INNER JOIN drug_order d ON d.order_id=orders.order_id WHERE e.patient_id=pat_id AND drug_inventory_id=drugid ORDER BY encounter_datetime ASC LIMIT 1);

RETURN dispensed_date;
END;
EOF
  end

  def self.down
=begin
    ActiveRecord::Base.connection.execute <<EOF
CREATE FUNCTION drug_first_dispensed_date(pat_id int,drugid int) RETURNS VARCHAR(10) 
DETERMINISTIC
BEGIN
DECLARE dispensed_date VARCHAR(10);

set dispensed_date = (SELECT DATE(e.encounter_datetime) FROM encounter e INNER JOIN orders ON orders.encounter_id=e.encounter_id AND orders.voided=0 INNER JOIN drug_order d ON d.order_id=orders.order_id WHERE e.patient_id=pat_id AND drug_inventory_id=drugid ORDER BY encounter_datetime ASC LIMIT 1);

RETURN dispensed_date;
END;
EOF
=end
    ActiveRecord::Base.connection.execute <<EOF
DROP FUNCTION IF EXISTS drug_first_dispensed_date;
EOF
  end

end
