#
# Usage: sudo script/runner -e <ENV> script/reset_views.rb --complete  
# (needs sudo to write to log files)
# 
# Default ENV is development
# e.g.: script/runner -e production script/reset_views.rb 
#       script/runner script/reset_views.rb


MY_ENV = ARGV[1]
MY_ENV = 'development' unless MY_ENV =~ /development|production|test/

puts "Reseting views in #{MY_ENV} environment"

if ARGV.include?('--complete')

  puts 'Clearing schema_migrations, sessions, weight_for_heights'
  ActiveRecord::Base.connection.execute('DELETE FROM schema_migrations;')
  ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS sessions;')
  ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS weight_for_heights;')

  puts 'Running database migrations'
  output = `rake db:migrate RAILS_ENV=#{MY_ENV}`
  puts output

  puts 'Loading default fixtures'
  output = `rake openmrs:bootstrap:load:defaults RAILS_ENV=#{MY_ENV}`
  puts output
end


puts 'Resetting Start Dates ....'
PatientStartDate.reset
puts 'Resetting Registration Dates ....'
PatientRegistrationDate.reset
puts 'Resetting Adherence Dates ....'
PatientAdherenceDate.reset
puts 'Resetting Adherence Rates ....'
PatientAdherenceRate.reset
puts 'Resetting Prescription Total ....'
PatientPrescriptionTotal.reset
puts 'Resetting Whole Tables Remaining and Brought ....'
PatientWholeTabletsRemainingAndBrought.reset
puts 'Resetting Historical Outcomes ....'
PatientHistoricalOutcome.reset
puts 'Resetting Historical Regimens ....'
PatientHistoricalRegimen.reset

=begin
puts 'Ignore outcomes after death date'
ActiveRecord::Base.connection.execute <<EOF
DELETE FROM patient_historical_outcomes
  USING patient_historical_outcomes INNER JOIN 
  (
  SELECT * FROM patient_historical_outcomes
  WHERE outcome_concept_id = 322
  ORDER BY patient_id, outcome_date, outcome_concept_id
  ) AS deaths ON patient_historical_outcomes.patient_id = deaths.patient_id
WHERE deaths.outcome_date < patient_historical_outcomes.outcome_date AND patient_historical_outcomes.outcome_concept_id = 373;
EOF
=end



