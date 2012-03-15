GIVE_ENCOUNTER_ID = EncounterType.find_by_name('Give drugs').id

  def update_regimen
    count = 0
    regimens = {}
    durations = {}
    
    File.open(File.join("/home/ace/Desktop/time_period.csv"), File::RDONLY).readlines[1..-1].each{|line|
      data_row = line.chomp.split(",").collect{|text|text.gsub(/"/,"")} 
      encounter_id = data_row[2].to_i rescue 0
      next if encounter_id == 0
      case data_row[4]
        when "1 month"
          duration = 30
        when "2 months"
          duration = 60
        when "3 months"
          duration = 90
        when "15 days"
          duration = 15
        else
          duration = 30
      end
      durations[encounter_id] = duration
    }
    
    File.open(File.join("/home/ace/Desktop/current_patient_regimen.csv"), File::RDONLY).readlines[1..-1].each{|line|
      prescription = nil  
      data_row = line.chomp.split(",").collect{|text|text.gsub(/"/,"")} 
      patient_id =  data_row[0] ; encounter_id = data_row[1] ; encounter_date = data_row[2]
      regimen_id =  data_row[3] ; location_id = data_row[4]

      regimen_concept_id = PatientHistoricalRegimen.find(:first,:conditions => ["patient_id = ? AND DATE(dispensed_date) = ?",
                               patient_id,encounter_date.to_date]).regimen_concept_id rescue 0

      next if regimen_concept_id == 0 and regimen_id == '999'
      next if regimen_concept_id == regimen_id.to_i
      regimen_id = regimen_concept_id if regimen_id == '999'
 
      encounter = Encounter.find(encounter_id)
      patient = Patient.find(patient_id) rescue nil
      next if patient.blank?
      Location.set_current_location = Location.find(location_id)
      age = patient.age(encounter_date.to_date)
      weight = patient.current_weight
      if weight.blank? and age > 19
        weight = 42
      elsif weight.blank? and age < 20
        weight = 25
      elsif weight.blank? and age < 10
        weight = 14
      end   

      if weight and regimen_id != "999"
        regimen_names = Concept.find(regimen_id).concepts.map{|c|c.name}
        regimen_names.each{|regimen_name|
          if regimen_name.match("Stavudine Lamivudine Nevirapine")  
            if weight <= 30
              regimen_name = "Stavudine Lamivudine + Stavudine Lamivudine Nevirapine (Triomune Baby)" if durations[encounter.id] == 15
              regimen_name = "Stavudine Lamivudine Nevirapine (Triomune Baby)"
            elsif durations[encounter.id] == 15
              regimen_name = "Stavudine Lamivudine + Stavudine Lamivudine Nevirapine"
            end  
          end  
          prescription = DrugOrder.recommended_art_prescription(weight)[regimen_name]
          break unless prescription.blank?
        }
      end  
      
      unless prescription.blank?
        dispensed_drugs = Hash.new(0)
        prescription.map{|presc|
          dispensed_drugs[presc.drug_inventory_id]+= presc.units
        }

        encounter.void!("Switched to another regimen")
        
        dispensed_drugs.each do |drug_id,pill_per_day|
          order = Order.new
          order.order_type_id = 1
          order.orderer = User.current_user.id
          order.encounter_id = encounter.id
          order.save

          pills = (pill_per_day * durations[encounter.id]) || 60

          drug_order = DrugOrder.new
          drug_order.order = order
          drug_order.drug_inventory_id = drug_id
          drug_order.quantity = pills
          drug_order.save
          puts "#{pills}>>>>>>>>>>>>>>>>> #{pill_per_day} ============ #{durations[encounter.id]}"
        end 
      end  
    }
  end

  User.current_user = User.find(1)
  update_regimen
