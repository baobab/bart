GIVE_ENCOUNTER_ID = EncounterType.find_by_name('Give drugs').id

  def update_regimen
    count = 0
    
    File.open(File.join("/home/ace/Desktop/zch/zch_fixed_regimens.csv"), File::RDONLY).readlines[1..-1].each{|line|
      data_row = line.chomp.split(",").collect{|text|text.gsub(/"/,"")} 
      patient_id =  data_row[0] ; arv_number = data_row[1] ; prefix = data_row[2]
      arv_number_without_prefix =  data_row[3] ; encounter_datetime = data_row[4] ; regimen = data_row[5]
      pills = data_row[6] ; drug_given = data_row[7]
      patient = Patient.find(patient_id)
      patient_age = patient.age(encounter_datetime.to_date)


      encounter = Encounter.find(:all,
                  :joins => "INNER JOIN orders o ON o.encounter_id = encounter.encounter_id",
                  :conditions => ["encounter_type = 3 AND encounter.patient_id = ? 
                  AND encounter_datetime >= ? AND encounter_datetime <= ? AND voided = 0",
                  patient_id,encounter_datetime.to_date.strftime('%Y-%m-%d 00:00:00'),encounter_datetime.to_date.strftime('%Y-%m-%d 23:59:59')],
                  :order => "encounter_datetime desc")

      orders = []
      encounter.each do |encounter|
        order = encounter.orders rescue []
        next if order.blank?
        encounter.void!("Given another regimen")
      end

      new_encounter = Encounter.new()
      new_encounter.patient_id = patient_id
      new_encounter.encounter_datetime = encounter_datetime.to_date.strftime('%Y-%m-%d 00:00:00')
      new_encounter.encounter_type = GIVE_ENCOUNTER_ID
      new_encounter.save

      drug_given.split('-').each do |drug|
        drug_id = drug.split(';')[0] ; quantity = drug.split(';')[1] ; number_of_packs = drug.split(';')[2].to_i
        order = Order.new
        order.order_type_id = 1
        order.orderer = User.current_user.id
        order.encounter_id = new_encounter.id
        order.save

        1.upto(number_of_packs){ |pack_index|
          drug_order = DrugOrder.new
          drug_order.order = order
          drug_order.drug_inventory_id = drug_id
          drug_order.quantity = quantity
          drug_order.save
        }
      end
      puts "Done with #{patient.name} ::: row #{count+=1}"
    }
  end

  User.current_user = User.find(1)
  update_regimen
