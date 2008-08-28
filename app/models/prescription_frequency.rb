class PrescriptionFrequency < ActiveRecord::Base
  set_table_name :prescription_frequencies
end

=begin
DROP TABLE IF EXISTS prescription_frequencies;
CREATE TABLE prescription_frequencies (
  `id` int(11) NOT NULL auto_increment,
  `frequency` varchar(255) NOT NULL,
  `frequency_days` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `frequency_index` (`frequency`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO prescription_frequencies (frequency, frequency_days) VALUES
  ('Once', 1),
  ('Morning', 1),
  ('Evening', 1),
  ('Weekly', 7);
=end
