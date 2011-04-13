class CreateAgeFunction < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute <<EOF
DROP FUNCTION IF EXISTS age;
EOF

    ActiveRecord::Base.connection.execute <<EOF
CREATE FUNCTION age(birthdate varchar(10),visit_date varchar(10),date_created varchar(10),est int) RETURNS INT 
DETERMINISTIC
BEGIN
DECLARE n INT;

DECLARE birth_month INT;
DECLARE birth_day INT;

DECLARE year_when_patient_created INT;

DECLARE cur_month INT;
DECLARE cur_year INT;

set birth_month = (select MONTH(FROM_DAYS(TO_DAYS(birthdate))));
set birth_day = (select DAY(FROM_DAYS(TO_DAYS(birthdate))));

set cur_month = (select MONTH(CURDATE()));
set cur_year = (select YEAR(CURDATE()));

set year_when_patient_created = (select YEAR(FROM_DAYS(TO_DAYS(date_created))));

set n =  (SELECT DATE_FORMAT(FROM_DAYS(TO_DAYS(visit_date)-TO_DAYS(DATE(birthdate))), '%Y')+0);

if birth_month = 7 and birth_day = 1 and est = 1 and cur_month < birth_month and year_when_patient_created = cur_year then set n=(n + 1);
end if;

RETURN n;
END;
EOF
  end

  def self.down
    ActiveRecord::Base.connection.execute <<EOF
DROP FUNCTION IF EXISTS `age`;
EOF
  end
end
