class Encounter < OpenMRS
  set_table_name "encounter"
  has_many :observations, :foreign_key => :encounter_id, :dependent => :destroy do
    def find_by_concept_id(concept_id)
      find(:all, :conditions => ["voided = 0 and concept_id = ?", concept_id])
    end
    def find_by_concept_name(concept_name)
      find(:all, :conditions => ["voided = 0 and concept_id = ?", Concept.find_by_name(concept_name).id])
    end
    def find_first_by_concept_name(concept_name)
      find(:first, :conditions => ["voided = 0 and concept_id = ?", Concept.find_by_name(concept_name).id], :order => "obs_datetime")
    end
    def find_last_by_concept_name(concept_name)
      find(:first, :conditions => ["voided = 0 and concept_id = ?", Concept.find_by_name(concept_name).id], :order => "obs_datetime DESC")
    end
  end
  has_many :orders, :foreign_key => :encounter_id, :dependent => :destroy
  has_many :drug_orders, :through => :orders, :foreign_key => 'order_id'
  has_many :notes, :foreign_key => :encounter_id, :dependent => :destroy
  has_many :concept_proposals, :foreign_key => :encounter_id, :dependent => :destroy
  belongs_to :patient, :foreign_key => :patient_id
  belongs_to :type, :class_name => "EncounterType", :foreign_key => :encounter_type
  belongs_to :provider, :class_name => "User", :foreign_key => :provider_id
  belongs_to :created_by, :class_name => :user, :foreign_key => :creator
  belongs_to :form
  belongs_to :location

  set_primary_key "encounter_id"

  def name
    return self.type.name unless self.type.nil?
  end

  def to_s
    "Encounter:#{self.patient.name rescue ''} #{name} Observations:#{observations.length}"
  end

  # NOTE most ART prescription information is stored in the csv file
  # CPT dosage and ITN is stored here
  def to_prescriptions
    return nil unless self.name == "ART Visit"
    concept_prescribe_cotrimoxazole = Concept.find_by_name("Prescribe Cotrimoxazole (CPT)")
    concept_prescribe_itn = Concept.find_by_name("Prescribe Insecticide Treated Net (ITN)")
    concept_yes = Concept.find_by_name("Yes")
    prescriptions = Array.new
    time_period = ""
    amount_remaining_from_last_visit = Hash.new(0)
    self.observations.each{|observation|
      amount_remaining_from_last_visit[observation.drug] = observation.value_numeric if observation.concept.name =~ /remaining/
    }
    self.observations.each{|observation|
      if observation.concept_id == Concept.find_by_name("Prescription Time Period").id
        time_period = observation.value_text
      end
      if observation.drug
        next if observation.concept.name =~ /remaining/
        prescriptions << Prescription.new(observation.drug, observation.value_text, observation.value_numeric, time_period, amount_remaining_from_last_visit[observation.drug])
      elsif observation.concept_id == concept_prescribe_cotrimoxazole.id && observation.value_coded == concept_yes.id
        cotrimoxazole_drug = Drug.find_by_name("Cotrimoxazole 480")
        age_in_months = self.patient.age_in_months
        if age_in_months > 14*12
          prescriptions << Prescription.new(cotrimoxazole_drug, "Morning", 1, time_period)
          prescriptions << Prescription.new(cotrimoxazole_drug, "Evening", 1, time_period)
        elsif age_in_months > 5*12
          prescriptions << Prescription.new(cotrimoxazole_drug, "Morning", 1, time_period)
        elsif age_in_months > 6
          prescriptions << Prescription.new(cotrimoxazole_drug, "Morning", "1/2", time_period)
        elsif age_in_months > 1
          prescriptions << Prescription.new(cotrimoxazole_drug, "Morning", "1/4", time_period)
        end
      elsif observation.concept_id == concept_prescribe_itn.id && observation.value_coded == concept_yes.id
        itn_drug = Drug.find_by_name("Insecticide Treated Net")
        prescriptions << Prescription.new(itn_drug, "Once", "1", time_period)
      end
    }
# set the time period for all of these since it might not get set above (depends on order of observations)
    prescriptions.each{|prescription|
      prescription.time_period = time_period
    }

    return prescriptions

  end

  def to_dispensations
    prescriptions = self.to_prescriptions
    dispensations = Hash.new
#    raise prescriptions.collect{|p|" " + p.quantity.to_s}.to_s
    prescriptions.each{|prescription|
			next if prescription.nil? or prescription.drug.nil?
      dispensations[prescription.drug.id] = 0 if dispensations[prescription.drug.id].nil?
#      raise prescription.to_yaml if prescription.quantity.nil?
      dispensations[prescription.drug.id] += prescription.quantity
    }

    # Make the required amount match the actual pack amounts that should be available
    dispensations.each{|drug_id, required_quantity|
      available_pack_sizes = DrugBarcode.find_all_by_drug_id(drug_id).collect{|db|db.quantity}.uniq.sort
      next if available_pack_sizes.nil?

      # Changed <= to < in line below to fix Bug #185 - Starter pack prescriptions are wrong
      #closest_pack_size = available_pack_sizes.delete_if{|pack_quantity| pack_quantity <= required_quantity}.first
      closest_pack_size = available_pack_sizes.delete_if{|pack_quantity| pack_quantity < required_quantity}.first
      
      # If none of the pack sizes match, then try combining pack sizes
      if closest_pack_size.nil?
        available_combinations = available_pack_sizes.collect{|pack_quantity|[pack_quantity*2, pack_quantity*3, pack_quantity*4, pack_quantity*5, pack_quantity*6]}
        closest_pack_size = available_pack_sizes.delete_if{|pack_quantity| pack_quantity <= required_quantity}.first
      end

      dispensations[drug_id] = closest_pack_size unless closest_pack_size.nil?
    }

    return dispensations
    
  end

  def regimen
    return nil if self.name != "Give drugs"
    return @@dispensation_encounter_regimen_names[self.encounter_id] unless @@dispensation_encounter_regimen_names.blank?
    r = DrugOrder.drug_orders_to_regimen(self.drug_orders)
    r.name if r

# This code seems wrong, replaced with single regimen check
#    drug_array = self.orders.map(&:drug_orders).flatten.map(&:drug).map(&:concept).map(&:name)
#
#    # Check to see if the drug array contains the drugs required for the various regimens
#    return Concept.find_by_name("ARV First line regimen") if (["Stavudine Lamivudine Nevirapine"] - drug_array).empty?
#    return Concept.find_by_name("ARV First line regimen alternatives") if (["Stavudine Lamivudine", "Efavirenz"] - drug_array).empty?
#    return Concept.find_by_name("ARV First line regimen alternatives") if (["Zidovudine Lamivudine", "Nevirapine"] - drug_array).empty?
#    return Concept.find_by_name("ARV Second line regimen") if (["Abacavir", "Didanosine", "Lopinavir Ritonavir"] - drug_array).empty?
#    return Concept.find_by_name("ARV Second line regimen") if (["Zidovudine Lamivudine", "Tenofovir", "Lopinavir Ritonavir"] - drug_array).empty?
  end

  def self.find_by_date(date)
    Encounter.find(:all, :conditions => ["DATE(encounter_datetime) = ?",date])
  end

  def next_encounter_types(programs)

    next_encounter_types = Array.new
    programs.each{|program| 
      case program.name
        when "HIV"
          encounter_mappings = {
            nil => ["HIV Reception"],
            "HIV Reception" => ["HIV First visit", "Height/Weight"],
            "HIV First visit" => ["Height/Weight"],
            "Height/Weight" => ["HIV Staging", "ART Visit"],
          }
          collect_pre_art_data = GlobalProperty.find_by_property("collect_pre_art_data")
          if collect_pre_art_data.nil? or collect_pre_art_data.property_value == "false"
            encounter_mappings["HIV Staging"] = ["ART Visit"]
          end
# If they are a transfer in with a letter we want the receptionist to copy the staging info using the retrospective staging form
          if self.patient.transfer_in_with_letter? == true
            encounter_mappings["HIV First visit"] = ["HIV Staging"]
            encounter_mappings["HIV Staging"] = ["Height/Weight"]
          end
        when "Tuberculosis (TB)"
          encounter_mappings = {
            nil => ["TB Reception"],
          }
      end
     
      if self.name == "ART Visit"
      	clinician_referral = self.observations.find_by_concept_name("Refer patient to clinician").first
          next_encounter_types << "ART Visit" unless clinician_referral.nil? or clinician_referral.answer_concept.name != "Yes" 
      end 
      next_encounter_types << encounter_mappings[self.name]
    }
    return next_encounter_types.flatten.compact
  end
  
  def self.art_total_number_of_patients_visit(date,enc_type)
   date=date.to_date.strftime("%Y-%m-%d")
   Encounter.find(:all, :include => "patient", :conditions => ["DATE(encounter_datetime) = ? and encounter_type=?",date,enc_type]).collect{|e|e.patient if e.patient.art_patient? and (e.patient.patient_and_guardian_present?(date)=="Patient" || e.patient.patient_and_guardian_present?(date)=="Patient/guardian")}.compact.uniq
  end
  
  def self.count_encounters_by_type_for_date(date)
    todays_encounters = Encounter.find(:all, :include => "type", :conditions => ["DATE(encounter_datetime) = ?",date])
    encounters_by_type = Hash.new(0)
    todays_encounters.each{|encounter|
      next if encounter.type.nil?
      encounters_by_type[encounter.type] += 1
    }
    return encounters_by_type
  end
 
  def self.number_patients(date,encounter_type = "HIV Reception") 
    enc_type_id = EncounterType.find_by_name(encounter_type).id
    return Encounter.count(:all,:conditions => ["DATE(encounter_datetime) = ? and encounter_type=?",date,enc_type_id])
  end

  def self.count_total_number(date) 
    enc_type=EncounterType.find_by_name("HIV Reception").id
    return Encounter.find(:all,:include => "patient",:conditions => ["DATE(encounter_datetime) = ? and encounter_type=?",Date.today,enc_type]).collect{|pat|
    if Patient.find(pat.patient_id).filing_number !=""
        Patient.find(pat.patient_id).filing_number
    end 
    }.uniq.compact.length
  end


  def arv_given?
    self.orders.each{|order|
      order.drug_orders.each{|drug_order|
        return true if drug_order.drug.arv?
      }
    }
    return false
  end

  def add_observation(concept_id)
    observation = Observation.new
    observation.patient_id = self.patient_id
    observation.concept_id = concept_id
    observation.encounter = self
    observation.obs_datetime = self.encounter_datetime
    observation.location_id = Location.current_location
    return observation
  end

  def parse_observations(params)
    initiation_date = nil
    unless params[:observation].nil?

      if self.name == 'ART Visit'
        # TODO: Fix me!!
        # Rails doesn't include fields into params if none of its options are selected
        # So, save Nos if no symptom under Symptoms or Symptom continued.. is selected
        symptom_concept = Concept.find_by_name('Symptoms')
        symptom_continued_concept = Concept.find_by_name("Symptoms continued..")
        [symptom_concept, symptom_continued_concept].each{|concept|
          if params[:observation]["select:"+concept.id.to_s].nil?
            self.save_multiple_observations(concept, [''])
          end
        }
      end

      provider_username = params["alpha:#{Concept.find_by_name("Provider").id}"]
      unless provider_username.nil?
        provider = User.find_by_username(provider_username)
        self.provider_id = provider.user_id unless provider.nil?
      end

      # First find all dates then, create datetimes and save them as observations
      concepts = Hash.new
      params.each{|key,value| 
      # match 1212_year
        concepts[$1] = true if key =~ /(\d+)_(year|month|day)/
      }

      concepts.keys.each{|concept_id|
        # Assemble full date objects for each concept, handling unknowns appropriately
        year =  params["#{concept_id}_year"]
        month =  params["#{concept_id}_month"]
        day =  params["#{concept_id}_day"]
        # ignore if they are blank
        next if year == "" or month == "" or day == ""
        estimated = false
        if year == "Unknown"
          observation = self.add_observation(concept_id)
          observation.value_coded = Concept.find_by_name("Unknown").id
          observation.value_modifier = "es" if estimated
          observation.save
          next
        end
        if month == "Unknown"
          month = 7
          day = 1
          estimated = true
        end
        if day == "Unknown"
          day = 15
          estimated = true
        end
        date = Date.new(year.to_i,month.to_i,day.to_i).to_s
        observation = add_observation(concept_id)
        observation.value_datetime = date
        observation.value_modifier = "es" if estimated
        observation.save

        # initiation date will be used as obs_datetime for vitals
        if self.name == "HIV First visit"
          initiation_date = date if observation.concept.name == "Date of ART initiation"
        end
      }
    end


    params["observation"].each{|type_and_concept_id,answer|
      next if "" == answer
      type, concept_id = type_and_concept_id.split(":")
      next if type.nil? or concept_id.nil?
      if concept_id.to_i == Concept.find_by_name('Provider').id
        self.provider_id = User.find_by_username(answer).id rescue nil
        next
      end
      observation = self.add_observation(concept_id)
      need_save = true
			if answer == "Missing"
				observation.value_coded = Concept.find_by_name("Missing").id
      elsif answer.class == String and answer.downcase == 'unknown'
				observation.value_coded = Concept.find_by_name("Unknown").id
			else
				case type
					when "select"
            if answer.class == Array # for multi_select like symptoms
              self.save_multiple_observations(Concept.find(concept_id), answer)
              need_save = false
            else              
              observation.value_coded = answer
            end
					when "number" 
						if answer.match(/^(>|<|=)(\d+)/)
							# allow modifiers (like in CD4 counts)
							observation.value_modifier = $1
							observation.value_numeric = $2
            else
							observation.value_numeric = answer
						end
					when "location" then observation.value_numeric = Location.find_or_create_by_name(answer).id #location will be an id - create it if it doesn't exist
					when "alpha"  then observation.value_text = answer
					else               observation.value_text = answer
				end
			end

      if self.name == "HIV First visit" and (observation.concept.name == "Height" or 
           observation.concept.name == "Weight")
        observation.obs_datetime = initiation_date
      end
      observation.save if need_save
      
			
    } unless params["observation"].nil?


    params["observation_multi"].each{|concept_id|
      observation = self.add_observation(concept_id,encounter)
      observation.value_coded = Concept.find_by_name("Yes").id
      observation.save
    } unless params["observation_multi"].nil?

  end

  # Save each non-selected option as No and the selected ones as Yes unknown cause
  # on a select with multiple options
  # Params:
  #   concept object 
  #   answers array of answer concept id strings e.g. ["94", "417"]
  #
  # e.g.: self.save_multiple_observations(Concept.find(407), ['94', '417'])
  #
  def save_multiple_observations(concept, answers)
    concept.answer_options.each{|option|
      observation = self.add_observation(option.id)
      if answers.include?(option.id.to_s)
        observation.value_coded = Concept.find_by_name('Yes unknown cause').id
      else
        observation.value_coded = Concept.find_by_name('No').id
      end
      observation.save
    }
  end

  # override model/open_mrs.rb's void! since encounter has no void attributes
  def void!(reason)
    return if reason.blank?

    # void this encounter's observations
    self.observations.each{|observation|
      observation.void!(reason)
    } unless self.name == "Give drugs"

    # void this encounter's orders
    self.orders.each{|order|
      order.void!(reason)
    } if self.name == "Give drugs"

  end

  def voided?
    
    # check void status for encounter's orders if its a Dispensation 
    self.drug_orders.each{|drug_order|
      return false unless drug_order.order.voided?
    } if self.name == "Give drugs"

    # check void status of this encounter's observations
    self.observations.each{|observation|
      return false unless observation.voided?
    } unless self.name == "Give drugs"
    
    return true
  end
                          
  def void_reason
    return nil unless self.voided?

    # get void reason from the first observation or order
    unless self.name == "Give drugs"
      first_observation = self.observations.first
      return first_observation.void_reason unless first_observation.blank?
    else
      first_order = self.orders.first
      return first_order.void_reason unless first_order.blank?
    end
    nil
  end

  # USED IN CONSOLE!
  def self.check_for_valid_encounters(date = Date.today)
    Encounter.find_by_date(date).collect{|e|e.patient}.uniq.collect{|p|p.valid_visit?(date)}
  end

  def self.invalid_visit_patients(date = Date.today)
    Encounter.find_by_date(date).collect{|e|e.patient if e.patient}.compact.uniq.collect{|p| 
      p unless p.valid_visit?(date)
    }.compact
  end

  def retrospective?
    return true if self.encounter_datetime.hour == 0 and self.encounter_datetime.min == 0 and self.encounter_datetime.sec == 1
    false
  end
  
  # This is probably not the right place to put this, it should be label.draw_encounter 
  # or something... but this works, just keep in mind it is adding content to the 
  # label and therefore is probably breaking the law of demeter.
  def to_label(label)
    return unless label
    label.draw_multi_text(type.name, {:font_reverse, true})
    label.draw_multi_text(observations.collect{|obs|obs.to_short_s}.join(", "), {:font_reverse, false})
  end

  # Crazy method to associate all dispensation encounters to regimen name
  cattr_reader :dispensation_encounter_regimen_names
  def self.cache_encounter_regimen_names
    results = ActiveRecord::Base.connection.select_all("
    SELECT satisfied_ingredients.encounter_id, parent_concept.name FROM (
     SELECT count(*), encounter.encounter_id, regimen_ingredient.concept_id FROM encounter
     INNER JOIN orders ON orders.encounter_id = encounter.encounter_id
     INNER JOIN drug_order ON drug_order.order_id = orders.order_id
     INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
     INNER JOIN drug_ingredient as dispensed_ingredient ON drug.concept_id = dispensed_ingredient.concept_id
     INNER JOIN drug_ingredient as regimen_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id 
     INNER JOIN concept as regimen_concept ON regimen_ingredient.concept_id = regimen_concept.concept_id 
     WHERE encounter.encounter_type = 3 AND regimen_concept.class_id = 18 AND orders.voided = 0
     GROUP BY encounter.encounter_id, regimen_ingredient.concept_id, regimen_ingredient.ingredient_id) as satisfied_ingredients
    INNER JOIN concept_set AS parent_concept_set ON parent_concept_set.concept_id = satisfied_ingredients.concept_id
    INNER JOIN concept AS parent_concept ON parent_concept.concept_id = parent_concept_set.concept_set
    GROUP BY satisfied_ingredients.encounter_id, satisfied_ingredients.concept_id
    HAVING count(*) = (SELECT count(*) FROM drug_ingredient WHERE drug_ingredient.concept_id = satisfied_ingredients.concept_id)")
    @@dispensation_encounter_regimen_names = Hash.new
    results.each{|r| @@dispensation_encounter_regimen_names[r["encounter_id"].to_i] = r["name"]}  
    @@dispensation_encounter_regimen_names
  end
         
  def self.count_encounters_by_type_age_and_date(date,encounter_type = "General Reception")
    enc_type_id = EncounterType.find_by_name(encounter_type).id
    #todays_encounters = Patient.find(:all, :conditions => ["DATE(date_created) = ?",date,enc_type_id],:group =>"patient_id")
    todays_encounters = Encounter.find_by_sql("select p.patient_id from encounter e join patient p where Date(e.date_created)='#{date}' and p.patient_id=e.patient_id and e.encounter_type=17 group by e.patient_id").collect{|p|p.patient_id} rescue nil
    patient_type = Hash.new(0)
    todays_encounters.each{|p_id|
      patient =  Patient.find(p_id)
      patient_type["> 16,(#{patient.gender.first})"] += 1 if patient.age >= 16 and patient.gender == "Female"
      patient_type["> 16,(#{patient.gender.first})"] += 1 if patient.age >= 16 and patient.gender == "Male"
      patient_type["1 to 16,(#{patient.gender.first})"] += 1 if patient.age < 16 and patient.age >= 1  and patient.gender == "Female"
      patient_type["1 to 16,(#{patient.gender.first})"] += 1 if patient.age < 16 and patient.age >= 1  and patient.gender == "Male"
      patient_type["New born to 1,(#{patient.gender.first})"] += 1 if patient.age < 1  and patient.gender == "Female" 
      patient_type["New born to 1,(#{patient.gender.first})"] += 1 if patient.age < 1  and patient.gender == "Male"
    }
    patient_type
  end

  def self.follow_up_count_encounters_by_type_age_and_date(date,encounter_type = "General Reception")
    enc_type_id = EncounterType.find_by_name(encounter_type).id
    todays_encounters = Encounter.find_by_sql("select p.patient_id from encounter e join patient p where Date(e.date_created)='#{date}' and p.patient_id=e.patient_id and e.encounter_type=17 group by e.patient_id").collect{|p|p.patient_id} rescue nil
    patient_type = Hash.new(0)
    todays_encounters.each{|p_id|
      patient =  Patient.find(p_id)
      next if Encounter.count(:all,:conditions => ["encounter_type=? and patient_id=?",enc_type_id,patient.id],:limit => 2) < 2
      patient_type["> 16,(#{patient.gender.first})"] += 1 if patient.age >= 16 and patient.gender == "Female"
      patient_type["> 16,(#{patient.gender.first})"] += 1 if patient.age >= 16 and patient.gender == "Male"
      patient_type["1 to 16,(#{patient.gender.first})"] += 1 if patient.age < 16 and patient.age >= 1  and patient.gender == "Female"
      patient_type["1 to 16,(#{patient.gender.first})"] += 1 if patient.age < 16 and patient.age >= 1  and patient.gender == "Male"
      patient_type["New born to 1,(#{patient.gender.first})"] += 1 if patient.age < 1  and patient.gender == "Female" 
      patient_type["New born to 1,(#{patient.gender.first})"] += 1 if patient.age < 1  and patient.gender == "Male"
    }
    patient_type
  end
 
end



### Original SQL Definition for encounter #### 
#   `encounter_id` int(11) NOT NULL auto_increment,
#   `encounter_type` int(11) default NULL,
#   `patient_id` int(11) NOT NULL default '0',
#   `provider_id` int(11) NOT NULL default '0',
#   `location_id` int(11) NOT NULL default '0',
#   `form_id` int(11) default NULL,
#   `encounter_datetime` datetime NOT NULL default '0000-00-00 00:00:00',
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   PRIMARY KEY  (`encounter_id`),
#   KEY `encounter_location` (`location_id`),
#   KEY `encounter_patient` (`patient_id`),
#   KEY `encounter_provider` (`provider_id`),
#   KEY `encounter_type_id` (`encounter_type`),
#   KEY `encounter_creator` (`creator`),
#   KEY `encounter_form` (`form_id`),
#   CONSTRAINT `encounter_form` FOREIGN KEY (`form_id`) REFERENCES `form` (`form_id`),
#   CONSTRAINT `encounter_ibfk_1` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `encounter_location` FOREIGN KEY (`location_id`) REFERENCES `location` (`location_id`),
#   CONSTRAINT `encounter_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`),
#   CONSTRAINT `encounter_provider` FOREIGN KEY (`provider_id`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `encounter_type_id` FOREIGN KEY (`encounter_type`) REFERENCES `encounter_type` (`encounter_type_id`)
