-- 12  - WHO stage
-- 16 - WHO stage 3 adult, WHO stage 3 peds, WHO stage 4 adult, WHO stage 4 peds, CD4 count, lymphocyte count
SELECT * FROM (
  SELECT patient_start_dates.patient_id as patient_id, obs.obs_datetime as staging_date, obs.concept_id as who_stage_concept_id, who_stage_concepts.sort_weight as stage
  FROM patient_start_dates
  INNER JOIN concept_set AS who_stage_concepts ON who_stage_concepts.concept_set = 12
  INNER JOIN obs ON obs.concept_id = who_stage_concepts.concept_id AND obs.obs_datetime <= start_date AND obs.voided = 0
  ORDER BY who_stage_concepts.sort_weight DESC) as t
LEFT JOIN (SELECT value_coded AS cd4_count_less_than_250, cd4_count_less_than_250.patient_id 
           FROM patient_start_dates 
           LEFT JOIN obs as cd4_count_less_than_250 ON cd4_count_less_than_250.concept_id = 14 AND cd4_count_less_than_250.value_coded = 3 AND cd4_count_less_than_250.obs_datetime <= start_date AND cd4_count_less_than_250.voided = 0 
           ORDER BY cd4_count_less_than_250.obs_datetime DESC) as t2 ON t2.patient_id = t.patient_id
LEFT JOIN (SELECT value_numeric AS cd4_count, cd4_count.patient_id 
           FROM patient_start_dates 
           LEFT JOIN obs as cd4_count ON cd4_count.concept_id = 14 AND cd4_count.obs_datetime <= start_date AND cd4_count.voided = 0 
           ORDER BY cd4_count.obs_datetime DESC) as t3 ON t3.patient_id = t.patient_id
LEFT JOIN (SELECT value_numeric AS lymph_count, lymph_count.patient_id 
           FROM patient_start_dates 
           LEFT JOIN obs as lymph_count ON lymph_count.concept_id = 23 AND lymph_count.obs_datetime <= start_date AND lymph_count.voided = 0 
           ORDER BY lymph_count.obs_datetime DESC) as t4 ON t4.patient_id = t.patient_id
GROUP BY t.patient_id


--CD4 count < 250, Yes 14
--CD4 count, value_numeric 321

--Lymphocyte count 23
--Lymphocyte count below threshold with WHO stage 2 346

--27  - WHO stage 4 adult
--24  - WHO stage 4 peds
--25  - WHO stage 3 adult
--26  - WHO stage 3 peds
--37  - WHO stage 2 adult
--135 - WHO Stage 2 peds
--36  - WHO stage 1 adult
--134 - WHO Stage 1 peds
