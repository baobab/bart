class CreateAgeGroupFunction < ActiveRecord::Migration
  def self.up
=begin
ActiveRecord::Base.connection.execute <<EOF
DELIMITER $$

DROP FUNCTION IF EXISTS age_group $$
CREATE FUNCTION age_group(birthdate varchar(10),visit_date varchar(10),date_created varchar(10),est int) RETURNS VARCHAR(25) 
DETERMINISTIC
BEGIN
DECLARE avg VARCHAR(25);
DECLARE mths INT;
DECLARE n INT;

set avg="none";
set n =  (SELECT age(birthdate,visit_date,date_created,est));
set mths = (SELECT extract(MONTH FROM DATE(visit_date))-extract(MONTH FROM DATE(birthdate)));

if n >= 1 AND n < 5 then set avg="1 to < 5";
elseif n >= 5 AND n <= 14 then set avg="5 to 14";
elseif n > 14 AND n < 20 then set avg="> 14 to < 20";
elseif n >= 20 AND n < 30 then set avg="20 to < 30";
elseif n >= 30 AND n < 40 then set avg="30 to < 40";
elseif n >= 40 AND n < 50 then set avg="40 to < 50";
elseif n >= 50 then set avg="50 and above";
end if;

if mths >= 0 AND mths < 6 and avg="none" then set avg="< 6 months";
elseif mths >= 6 AND n < 12 and avg="none"then set avg="6 months to < 1 yr";
end if;

RETURN avg;
END $$

DELIMITER ;
EOF
=end
  end

  def self.down
ActiveRecord::Base.connection.execute <<EOF
DROP FUNCTION IF EXISTS `age_group`;
EOF
  end
end
