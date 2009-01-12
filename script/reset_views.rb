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
  ActiveRecord::Base.connection.execute('DELETE FROM schema_migrations IF EXISTS schema_migrations;')
  ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS sessions;')
  ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS weight_for_heights;')

  puts 'Running database migrations'
  output = `rake db:migrate RAILS_ENV=#{MY_ENV}`
  puts output

  puts 'Loading default fixtures'
  output = `rake openmrs:bootstrap:load:defaults RAILS_ENV=#{MY_ENV}`
  puts output
end

puts 'Resetting Adherence Dates ....'
PatientAdherenceDate.reset
puts 'Resetting Prescription Total ....'
PatientPrescriptionTotal.reset
puts 'Resetting Whole Tables Remaining and Brought ....'
PatientWholeTabletsRemainingAndBrought.reset
puts 'Resetting Historical Outcomes ....'
PatientHistoricalOutcome.reset
puts 'Resetting Historical Regimens ....'
PatientHistoricalRegimen.reset
