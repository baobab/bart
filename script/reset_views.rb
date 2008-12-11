#
# Usage: script/runner script/reset_views.rb <ENV>
# 
# Default ENV is development
# e.g.: script/runner script/reset_views.rb production


MY_ENV = ARGV[0] || 'development'

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

puts 'Reseting ....'
PatientAdherenceDate.reset
PatientPrescriptionTotal.reset
PatientWholeTabletsRemainingAndBrought.reset
PatientHistoricalOutcome.reset
PatientHistoricalRegimen.reset
