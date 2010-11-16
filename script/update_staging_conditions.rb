#
# Usage: sudo script/runner -e <ENV> script/update_stating_conditions.rb <csv_file>
# (needs sudo to write to log files)
#
# Default ENV is development
# e.g.: script/runner -e production script/update_stating_conditions.rb /tmp/patients.csv

require 'fastercsv'

CSV_FILE = ARGV[0]
CD4_CONCEPT_ID = Concept.find_by_name('CD4 Count').id
LOW_CONCEPT_ID = Concept.find_by_name('CD4 Count < 250').id
YES_CONCEPT_ID = Concept.find_by_name('Yes').id
NO_CONCEPT_ID  = Concept.find_by_name('No').id


# Void existing observation if any and create a new one
def update_obs(encounter, concept_id, value_field, value)
  observations = encounter.observations.find_by_concept_id(CD4_CONCEPT_ID)
  unless observations.blank?
    o = observations[0]
    o.void!('Value updated')
  end

  encounter.observations.create!(
    :concept_id   => concept_id,
    value_field   => value,
    :obs_datetime => encounter.encounter_datetime,
    :creator      => 1,
    :encounter    => encounter,
    :patient      => encounter.patient
  )
end

FasterCSV.read(CSV_FILE).each do |row|
  puts row.join(',')
  arv_num, cd4_count, *concept_ids = row

  patient = Patient.find_by_arvnumber(arv_num)
  encounter = patient.staging_encounter

  cd4_count = cd4_count.to_i
  if cd4_count > 0
    if cd4_count >= 250
      update_obs(encounter, LOW_CONCEPT_ID, :value_coded, NO_CONCEPT_ID)
    else
      update_obs(encounter, LOW_CONCEPT_ID, :value_coded, YES_CONCEPT_ID)
    end
    update_obs(encounter, CD4_CONCEPT_ID, :value_numeric, cd4_count)
  end

  concept_ids.compact.each do |concept_id|
    update_obs(encounter, concept_id, :value_coded, YES_CONCEPT_ID)
  end
end

