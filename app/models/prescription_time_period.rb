class PrescriptionTimePeriod < ActiveRecord::Base
  set_table_name :prescription_time_periods
end

=begin
DROP TABLE IF EXISTS prescription_time_periods;
CREATE TABLE prescription_time_periods (
  `id` int(11) NOT NULL auto_increment,
  `time_period` varchar(255) NOT NULL,
  `time_period_days` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `time_period_index` (`time_period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- This applies the appropriate buffer period
INSERT INTO prescription_time_periods (time_period, time_period_days) VALUES
  ('2 weeks', 15),
  ('1 month', 30),
  ('2 months', 58),
  ('3 months', 86),
  ('4 months', 114),
  ('5 months', 142),
  ('6 months', 170);
=end