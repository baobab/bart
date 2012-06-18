class AdherenceCalculator < ActiveRecord::Migration
  def self.up
ActiveRecord::Base.connection.execute <<EOF
DROP FUNCTION IF EXISTS adherence_calculator;
EOF

    ActiveRecord::Base.connection.execute <<EOF
CREATE FUNCTION adherence_calculator(total_remaining DOUBLE, total_dispensed DOUBLE, daily_consumption DOUBLE,visit_date DATE,visit_date2 DATE) RETURNS DOUBLE
DETERMINISTIC                                                                   
BEGIN
DECLARE adherence DOUBLE;                                                               

set adherence = (SELECT 100*(SUM(total_dispensed)+SUM(total_remaining)-total_remaining)/((SUM(total_dispensed)+SUM(total_remaining) - (SUM(total_dispensed) + SUM(total_remaining) - (daily_consumption * DATEDIFF(visit_date,visit_date2))))));


if adherence > 100 then set adherence = (100 - (adherence - 100));                                    
end if;   

RETURN adherence;                                                                     
END;
EOF
  end

  def self.down
    ActiveRecord::Base.connection.execute <<EOF
DROP FUNCTION IF EXISTS `adherence_calculator`;
EOF
  end
end
