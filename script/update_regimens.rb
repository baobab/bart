#
# Usage: sudo script/runner -e <ENV> script/update_regimens.rb <csv_file>
# (needs sudo to write to log files)
#
# Default ENV is development
# e.g.: script/runner -e production script/update_regimens.rb /tmp/regimens.csv
#
# CSV Format
#
# Patient ID, ARV Number, Site_Code, ARV Number (without site code), visit_date,
#   Regimen Concept Id,
#
# e.g.
# 3345,"ZCH 3345","ZCH",3345,07/13/2010 12:00 AM,450,60,"5;60;1"
# 3936,"ZCH 3936","ZCH",3936,09/23/2010 12:00 AM,452,60,"1;60;1-7;30;1-16;60;1"

require 'fastercsv'
require 'json/add/rails'

CSV_FILE = ARGV[0]
User.current_user = User.find(1)

# void orders for the specified encounter
def void_drug_orders(encounter)
  encounter.orders.each do |o|
    puts "Voiding order ...: #{o.id}"
    o.void!('Wrong regimen')
  end
end

def create_encounter(patient, visit_date)
  e = Encounter.new(:patient => patient,
    :encounter_datetime => visit_date.to_time,
    :creator            => User.current_user,
    :provider_id        => User.current_user.id,
    :encounter_type     => EncounterType.find_by_name("Give drugs").id
  )
  e.save
  e
end

# save drug orders
#
# dispsensed_drugs {drug_id => [qty,pack]}
def update_drug_orders(encounter, dispensed_drugs)
  Order.transaction do
    DrugOrder.transaction do #makes sure that everything saves, if not roll it all back so we don't pollute the db   with half saved records
#      encounter = new_encounter_by_name("Give drugs")
      order_type = OrderType.find_by_name("Give drugs")
      dispensed_drugs.each{|drug_id, quantity_and_packs|
        number_of_orders = []
        quantity_and_packs.each do |quantity_and_pack|
          number_of_orders << [quantity_and_pack[0],quantity_and_pack[1]]
        end
        order = Order.new
        order.order_type = order_type
        order.orderer = User.current_user.id
        order.encounter = encounter
        order.save
        number_of_orders.each do |quantity_and_pack|
          number_of_packs = quantity_and_pack[1].to_i
          puts "drug:#{drug_id}"
          puts "packs:#{number_of_packs}"
          quantity = quantity_and_pack[0].to_i
          tablets_per_pack = quantity
          puts "qty:#{quantity}"
          1.upto(number_of_packs){ |pack_index|
            drug_order = DrugOrder.new
            drug_order.order = order
            drug_order.drug_inventory_id = drug_id
            drug_order.quantity = tablets_per_pack
            drug_order.save
            #Pharmacy.drug_dispensed_stock_adjustment(drug_id,tablets_per_pack,session[:encounter_datetime].to_date)
          }
        end
      }
      #encounter.save
    end
  end
end

def fix_drug_orders(encounter, drug_text)
  dispensed_drugs = {}
  drug_text.split('-').each do |i|
    drug_id, qty, packs = i.split(';').map(&:to_i)
    dispensed_drugs[drug_id] = {qty => packs}
  end

  void_drug_orders(encounter)
  update_drug_orders(encounter, dispensed_drugs)
  encounter.patient.reset_regimens
end

FasterCSV.read(CSV_FILE).each do |row|

  pat_id, arv_num, site, num, visit_date, regimen_id, qty, #old_regimen,
    drug_text = row

  patient = Patient.find_by_arvnumber(arv_num)
  if patient.nil?
    puts row.join(',') + "**********"

  else
    
    #patient.reset_regimens

    historical_regimens = patient.patient_historical_regimens.
      find(:all,
           :conditions => ["DATE(dispensed_date) = ?", visit_date.to_date],
           :order => 'dispensed_date DESC'
          ).compact
    historical_regimen = historical_regimens.first

    if historical_regimen.blank?
      if regimen_id
        
        
        encounter = patient.encounters.find(:first,
          :conditions => ['encounter_type = ? AND DATE(encounter_datetime) = ?',
            3, visit_date.to_date],
          :order => 'encounter_datetime DESC')

        encounter = create_encounter(patient, visit_date) unless encounter
        
        unless encounter
          puts "#{patient.id}, #{row.join(', ')},o-o-o-o-o!!"
        else
          puts "#{patient.id}, #{row.join(', ')},ooooooooo"
          fix_drug_orders(encounter, drug_text)
        end

      else
        puts "#{patient.id}, #{row.join(', ')},----------"
      end

    elsif regimen_id == historical_regimen.regimen_concept_id.to_s
      puts patient.id.to_s + ',' + row.join(',') + ",===" +
           historical_regimen.regimen_concept_id.to_s

    else
      
      puts patient.id.to_s + ',' + row.join(',') + ",~~~" +
           historical_regimen.regimen_concept_id.to_s

      fix_drug_orders(historical_regimen.encounter, drug_text)
    end
  end
end

