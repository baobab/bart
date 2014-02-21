# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

# Validation rules for cohort report
require 'fastercsv'
puts "Adding validation rules for cohort reports"
FasterCSV.foreach('db/validation_rules.csv',
                  :col_sep => ';', :headers => :first_row) do |row|
  expr = row['expr'] || ''
  desc = row['desc']
  type_id = row['type_id']
  if expr.match('^#').nil? and (expr+desc).strip.length > 0
    ValidationRule.create :expr => expr.strip, :desc => desc, :type_id => type_id
  end
end
