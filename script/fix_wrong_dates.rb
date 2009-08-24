#
# Fix encounters, with date_created earlier than when the system was deployed, and their respective observations and orders
#

EARLIEST_DATE = '2005-01-01'
LOG_FILE      = 'log/fix_wrong_dates.log'

def change_dates(from_id, to_id, new_date)  
  puts "Fixing #{new_date} ..."
  encounters = Encounter.find(:all,:conditions => ['encounter_id BETWEEN ? AND ?', from_id,to_id])
  encounters.each do |enc|
   
    old_date = enc.date_created
    diff_days = (new_date.to_date - enc.date_created.to_date).days
    offset_days = (encounters.last.date_created.to_date - enc.date_created.to_date).days
    enc.date_created += diff_days - offset_days
    enc.encounter_datetime += diff_days - offset_days
    enc.save
    `echo "Encounter #{enc.id} changed from #{old_date} to #{enc.date_created} on #{Time.now}" >> #{LOG_FILE}`

    # fix obs
    enc.observations.each do |o|
      o.obs_datetime = enc.encounter_datetime
      o.date_created = enc.encounter_datetime
      o.save
    end

    # orders
    enc.orders.each do |o|
      o.date_created = enc.encounter_datetime
      o.save
    end
    
  end
end

record_count = Encounter.count(:conditions => ['date_created < ?', EARLIEST_DATE])
if record_count < 1
  puts "There are no records created earlier than #{EARLIEST_DATE}"
  exit
end

puts "Fixing #{record_count} records ..."

# create required temporary tables
db_config = ActiveRecord::Base.configurations[RAILS_ENV]
output = `mysql -v -u #{db_config['username']} --password=#{db_config['password']} -h #{db_config['host']} #{db_config['database']} < script/fix_wrong_date_records.sql`
puts output

es = Encounter.find_by_sql('SELECT *
 FROM tmp2_ids
 INNER JOIN tmp2_next_ids USING(id) 
 ORDER BY record_id;')

es.each do |e|
  change_dates(e.record_id, e.next_id, e.next_date_created)
end

