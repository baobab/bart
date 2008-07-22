-- 143 = Concept "Date of ART initiation"
DROP VIEW IF EXISTS patient_dispensation_and_initiation_dates;
CREATE VIEW patient_dispensation_and_initiation_dates (patient_id, start_date) AS
   SELECT patient_id, dispensed_date AS start_date 
   FROM first_line_regimen_dispensations
   UNION SELECT patient_id, value_datetime AS start_date
   FROM obs
   WHERE concept_id = 143;


DROP VIEW IF EXISTS patient_start_dates;
CREATE VIEW patient_start_dates (patient_id, start_date) AS
  SELECT patient_id, MIN(start_date) AS start_date 
  FROM patient_dispensation_and_initiation_dates
  GROUP BY patient_id;

