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
  belongs_to :created_by, :class_name => "User", :foreign_key => :creator
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

  def self.find_by_user_and_date(user_id,date)
    Encounter.find(:all, :conditions => ["DATE(encounter_datetime) = ? and creator=?",date,user_id])
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

    if self.name == "General Reception"
      next_encounter_types << "Outpatient Diagnosis"
    end  

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
 
  def self.count_patients(date,encounter_type = "HIV Reception") 
    start_date = (date.to_date.to_s + " 00:00:00")
    end_date = (date.to_date.to_s + " 23:59:59")
    enc_type_id = EncounterType.find_by_name(encounter_type).id
    return Encounter.count('patient_id', :distinct => true,
                           :joins => "INNER JOIN patient p ON p.patient_id=encounter.patient_id",
                           :conditions => ["encounter_datetime >= ? AND encounter_datetime <=? 
                           AND encounter_type=? AND p.birthdate IS NOT NULL",
                           start_date,end_date,enc_type_id])
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
    params[:observation] = params["observation"] unless params[:observation].blank?
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
    
    arv_regimen_concept = Concept.find_by_name("ARV regimen")

    params["observation"].each{|type_and_concept_id,answer|
      type, concept_id = type_and_concept_id.split(":")
      next if answer.blank?
      next if type.nil? or concept_id.nil?
      next if type == "select" and concept_id.to_i == arv_regimen_concept.concept_id and answer == "Other"
      if concept_id.to_i == Concept.find_by_name('Provider').id
        self.provider_id = User.find_by_username(answer).id rescue nil
        next
      end
      concept = Concept.find(concept_id)
      observation = self.add_observation(concept_id)
      need_save = true
			if answer == "Missing"
				observation.value_coded = Concept.find_by_name("Missing").id
      elsif answer.class == String and answer.downcase == 'unknown'
				observation.value_coded = Concept.find_by_name("Unknown").id
			else
				case type
					when "select"
            next if concept.name == 'Side effects'
            if answer.class == Array # for multi_select like symptoms
              side_effect_answers = []
              if concept.name.include?('Symptoms')
                side_effects_concept = Concept.find_by_name('Side effects')
                side_effect_names = params['observation']["select:#{side_effects_concept.id}"] rescue []
                side_effect_answers = Concept.find_all_by_name(side_effect_names).map(&:id).map(&:to_s)
                answer -= side_effect_answers
              end
              self.save_multiple_observations(concept, answer, side_effect_answers)
              need_save = false
            else              
              observation.value_coded = answer
            end
					when "number" 
						if answer.match(/^(>|<|=)(\d.+)/)
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
  def save_multiple_observations(concept, answers, side_effects=[])
   
    positive_answer = 'Yes'
    answers -= side_effects
    answer_options = concept.answer_options
    if concept.name.include?('Symptoms')
      positive_answer = 'Yes unknown cause'
    end
    answer_options.each{|option|
      observation = self.add_observation(option.id)
      if side_effects.include?(option.id.to_s)
        observation.value_coded = Concept.find_by_name('Yes drug induced').id
      elsif answers.include?(option.id.to_s)
        observation.value_coded = Concept.find_by_name(positive_answer).id
      else
        observation.value_coded = Concept.find_by_name('No').id
      end
      observation.save
    }
  end

  # override model/open_mrs.rb's void! since encounter has no void attributes
  def void!(reason)
    return if reason.blank?
    date = self.encounter_datetime.to_date

    # void this encounter's observations
    self.observations.each{|observation|
      observation.void!(reason)
    }

    # void this encounter's orders
    self.orders.each{|order|
      order.drug_orders.each{|d|
        Pharmacy.new_delivery(d.drug_inventory_id,d.quantity,date)
      }
      order.void!(reason)
    }

    self.patient.reset_outcomes
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
    label.draw_multi_text(type.name, {:font_reverse => true})
    label.draw_multi_text(observations.collect{|obs|obs.to_short_s}.join(", "), {:font_reverse => false})
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
    start_date = (date.to_date.to_s + " 00:00:00")
    end_date = (date.to_date.to_s + " 23:59:59")
    enc_type_id = EncounterType.find_by_name(encounter_type).id
    groups = Encounter.find_by_sql("SELECT age,gender,count(*) AS total FROM 
            (SELECT age_group(p.birthdate,date(obs.obs_datetime),Date(p.date_created),p.birthdate_estimated) 
            as age,p.gender AS gender
            FROM `encounter` INNER JOIN obs ON obs.encounter_id=encounter.encounter_id
            INNER JOIN patient p ON p.patient_id=encounter.patient_id WHERE
            (encounter_datetime >= '#{start_date}' AND encounter_datetime <= '#{end_date}' 
            AND encounter_type=#{enc_type_id} AND obs.voided=0) GROUP BY encounter.patient_id 
            order by age) AS t group by t.age,t.gender")

    age_groups = {}
    groups.each{|group|
      age_groups[group.age] = {"Female" =>0,"Male" => 0} if age_groups[group.age].blank?
      age_groups[group.age][group.gender] = group.total.to_i rescue 0
    }

    age_groups
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
  
  def self.encounters_by_start_date_end_date_and_user(start_date,end_date,user_id)
    self.find(:all,:conditions => ["Date(encounter_datetime) >=? and Date(encounter_datetime) <=? and creator =?",start_date,end_date,user_id],:order =>"encounter_datetime desc") rescue nil
  end

  def update_outcomes
ActiveRecord::Base.connection.execute <<EOF
INSERT INTO patient_historical_outcomes (patient_id, outcome_date, outcome_concept_id)
  SELECT encounter.patient_id, encounter.encounter_datetime, 324
  FROM encounter
  INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
  INNER JOIN drug_order ON drug_order.order_id = orders.order_id 
  INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
  INNER JOIN concept_set as arv_drug_concepts ON
    arv_drug_concepts.concept_set = 460 AND
    arv_drug_concepts.concept_id = drug.concept_id
  WHERE encounter.encounter_id = #{self.id}
  UNION
  SELECT obs.patient_id, obs.obs_datetime, obs.value_coded 
  FROM obs  
  WHERE obs.concept_id = 28 AND obs.encounter_id = #{self.id} AND obs.voided = 0
  UNION
  SELECT obs.patient_id, obs.obs_datetime, 325 
  FROM obs 
  WHERE obs.concept_id = 372 AND obs.value_coded <> 3 AND obs.encounter_id = #{self.id} AND obs.voided = 0
  UNION
  SELECT obs.patient_id, obs.obs_datetime, 386 
  FROM obs 
  WHERE obs.concept_id = 367 AND obs.value_coded <> 3 AND obs.encounter_id = #{self.id} AND obs.voided = 0;
EOF

# This shows that encounter.update_outcomes does not update outcomes that are not triggered by encounter updates
=begin
  UNION
  SELECT patient_default_dates.patient_id, patient_default_dates.default_date, 373
  FROM patient_default_dates 
  WHERE patient_default_dates.patient_id = #{self.id}
  UNION
  SELECT patient.patient_id, patient.death_date, 322
  FROM patient
  WHERE patient.death_date IS NOT NULL AND patient.patient_id = #{self.id};
=end
  end

  def after_save
    encounter_patient = self.patient
    encounter_name = self.name

    if encounter_name == "Give drugs"
      encounter_patient.reset_regimens
      encounter_patient.reset_outcomes
      if encounter_patient.date_started_art 
        encounter_patient.reset_start_date if encounter_patient.date_started_art > self.encounter_datetime
      else
        encounter_patient.reset_start_date
      end
    elsif encounter_name == "HIV First visit" #TODO Do this only if transfer in(ie patient has date_of_art_initiation observation) 
      encounter_patient.reset_start_date
    elsif encounter_name == "ART Visit" || encounter_name == "Update outcome" #TODO  
      encounter_patient.reset_outcomes
    end

  end

  def hiv_stage(observation_date = Date.today)
    return nil if self.name != "HIV Staging"
      yes_concept = Concept.find_by_name "Yes"
      adult_or_peds = self.patient.child? ? "peds" : "adult"
	    calculated_stage = 1 # Everyone is supposed to be HIV positive so start them at 1
      staging_observations = self.observations rescue [] 

	    # loop through each of the stage defining conditions starting with the 
	    # the highest stages
	    4.downto(2){|stage_number|
	      Concept.find_by_name("WHO stage #{stage_number} #{adult_or_peds}").concepts.each{|concept|
		      break if calculated_stage > 1 # stop if we have found one already
		      staging_observations.each{|observation|
		      next unless observation.value_coded == yes_concept.id
		        if observation.concept_id == concept.id and (observation.obs_datetime == observation_date or observation.obs_datetime < observation_date)
		          calculated_stage = stage_number
		          break
		        end
		     } 
	      }
	    }
	    calculated_stage
  end  

  def reason_for_starting_art(observation_date)
    return nil if self.name != "HIV Staging"
     who_stage = self.hiv_stage(observation_date)
      adult_or_peds = self.patient.child? ? "peds" : "adult" #returns peds or adult
      #check if the first positive hiv test recorded at registaration was PCR 
            #check if patient had low cd4 count
      low_cd4_count = self.observations.find(:first,:conditions => ["((value_numeric <= ? AND concept_id = ?) OR 
                                             (concept_id = ? and value_coded = ?)) AND voided = 0 and DATE(obs_datetime) <= ?",250, 
                                             Concept.find_by_name("CD4 count").id, Concept.find_by_name("CD4 Count < 250").id, 
                                             (Concept.find_by_name("Yes").id rescue 3), observation_date]) != nil
      if self.patient.child?
        date_of_positive_hiv_test = self.patient.date_of_positive_hiv_test
        age_in_months = self.patient.age_in_months(date_of_positive_hiv_test)
        presumed_hiv_status_conditions = false
        low_cd4_percent = self.observations.find(:first,:conditions => ["(concept_id = ? and value_coded = ? AND voided = 0 AND DATE(obs_datetime) <= ?)", 
                                                   Concept.find_by_name("CD4 percentage < 25").id, 
                                                   (Concept.find_by_name("Yes").id rescue 3), observation_date]) != nil
        thresholds = {
            0=>4000, 1=>4000, 2=>4000, 
            3=>3000, 4=>3000, 
            5=>2500, 
            6=>2000, 7=>2000, 8=>2000, 9=>2000, 10=>2000, 11=>2000, 12=>2000, 13=>2000, 14=>2000, 15=>2000
          }
        low_lymphocyte_count = self.observations.find(:first, :conditions => ["value_numeric <= ? AND concept_id = ? AND voided = 0 AND \
                                                      DATE(obs_datetime) <= ?",thresholds[self.patient.age], 
                                                Concept.find_by_name("Lymphocyte count").id, observation_date]) != nil
        first_hiv_test_was_pcr = self.observations.find(:first,:conditions => ["(concept_id = ? and value_coded = ? AND voided = 0 AND \
                                                       DATE(obs_datetime) <= ?)", 
                                                      Concept.find_by_name("First positive HIV Test").id, 
                                                      (Concept.find_by_name("PCR Test").id rescue 463),observation_date]) != nil
        first_hiv_test_was_rapid = self.observations.find(:first,:conditions => ["(concept_id = ? and value_coded = ? AND voided = 0 AND \
                                                         DATE(obs_datetime) <= ?)", 
                                                      Concept.find_by_name("First positive HIV Test").id, 
                                                      (Concept.find_by_name("Rapid Test").id rescue 464), observation_date]) != nil
        pneumocystis_pneumonia = self.observations.find(:first,:conditions => ["(concept_id = ? and value_coded = ? AND voided = 0 AND \
                                                       DATE(obs_datetime) <= ?)", 
                                                      Concept.find_by_name("Pneumocystis pneumonia").id, 
                                                      (Concept.find_by_name("Yes").id rescue 3),observation_date]) != nil
        candidiasis_of_oesophagus = self.observations.find(:first,:conditions => ["(concept_id = ? and value_coded = ? AND voided = 0 AND \
                                                          DATE(obs_datetime) <= ?)", 
                                                      Concept.find_by_name("Candidiasis of oesophagus").id, 
                                                      (Concept.find_by_name("Yes").id rescue 3), observation_date]) != nil
        #check for Cryptococal meningitis or other extrapulmonary meningitis
        cryptococcal_meningitis = self.observations.find(:first,:conditions => ["(concept_id = ? and value_coded = ? AND voided = 0 AND \
                                                        )", 
                                                      Concept.find_by_name("Cryptococcal meningitis").id, 
                                                      (Concept.find_by_name("Yes").id rescue 3), observation_date]) != nil
        severe_unexplained_wasting = self.observations.find(:first,:conditions => ["(concept_id = ? and value_coded = ? AND voided = 0 AND \
                                                           DATE(obs_datetime) <= ?)",
                                              Concept.find_by_name("Severe unexplained wasting / malnutrition not responding to treatment(weight-for-height/ -age less than 70% or MUAC less than 11cm or oedema)").id,
                                              (Concept.find_by_name("Yes").id rescue 3), observation_date]) != nil
        toxoplasmosis_of_the_brain = self.observations.find(:first,:conditions => ["(concept_id = ? and value_coded = ? AND voided = 0 AND \
                                                           DATE(obs_datetime) <= ?)", 
                                              Concept.find_by_name("Toxoplasmosis of the brain (from age 1 month)").id, 
                                              (Concept.find_by_name("Yes").id rescue 3), observation_date]) != nil
        oral_thrush = self.observations.find(:first,:conditions => ["(concept_id = ? and value_coded = ? AND voided = 0 AND \
                                            DATE(obs_datetime) <= ?)", 
                                              Concept.find_by_name("Oral thrush").id, 
                                              (Concept.find_by_name("Yes").id rescue 3), observation_date]) != nil
        sepsis_severe = self.observations.find(:first,:conditions => ["(concept_id = ? and value_coded = ? AND voided = 0 AND \
                                              DATE(obs_datetime) <= ?)", 
                                              Concept.find_by_name("Sepsis, severe").id, 
                                              (Concept.find_by_name("Yes").id rescue 3), observation_date]) != nil
        pneumonia_severe = self.observations.find(:first,:conditions => ["(concept_id = ? and value_coded = ? AND voided = 0 AND DATE(obs_datetime) <= ?)", 
                                              Concept.find_by_name("Pneumonia, severe").id, 
                                              (Concept.find_by_name("Yes").id rescue 3), observation_date]) != nil
        if pneumocystis_pneumonia or candidiasis_of_oesophagus or cryptococcal_meningitis or severe_unexplained_wasting or toxoplasmosis_of_the_brain or (oral_thrush and sepsis_severe) or (oral_thrush and pneumonia_severe) or (sepsis_severe and pneumonia_severe)
          presumed_hiv_status_conditions = true
        end
        if age_in_months <= 17 and first_hiv_test_was_rapid and presumed_hiv_status_conditions
          return Concept.find_by_name("Presumed HIV Disease")
        elsif age_in_months <= 12 and first_hiv_test_was_pcr
          return Concept.find_by_name("PCR Test")
        elsif who_stage >= 3
          return Concept.find_by_name("WHO stage #{who_stage} #{adult_or_peds}")
        elsif low_cd4_count
          return Concept.find_by_name("CD4 count < 250")
        elsif low_cd4_percent
          return Concept.find_by_name("CD4 percentage < 25")
        elsif low_lymphocyte_count and who_stage >= 2
          return Concept.find_by_name("Lymphocyte count below threshold with WHO stage 2")
        end
      else #if patient is adult
        if(who_stage >= 3)
          return Concept.find_by_name("WHO stage #{who_stage} #{adult_or_peds}")
        else
          return Concept.find_by_name("CD4 count < 250") if low_cd4_count
        end
        return nil
      end


  end

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  def self.new_encounter_from_encounter_type_id(patient_id,encounter_type_id,session_date,session_location)
    encounter = Encounter.new
# encounters track the actual encounter with a patient. They can be entered in  retrospectively.
    encounter.encounter_type = encounter_type_id
    encounter.patient_id = patient_id

    encounter.provider_id = User.current_user.user_id

    if session_date
      encounter.encounter_datetime = session_date
    else
      encounter.encounter_datetime = Time.now
    end

    encounter.location_id = session_location if session_location # encounter_location gets set in the session if it is a transfer in
    encounter
  end

  def self.create(patient,params,session_date = nil,session_location = nil,enc_type_id = nil,tablets = nil)
    params[:encounter_type_id] = enc_type_id unless enc_type_id.blank?
    params["tablets"] = tablets unless tablets.blank?
    encounter = self.new_encounter_from_encounter_type_id(patient.id,params[:encounter_type_id],session_date,session_location)

    if patient.child? and encounter.name == 'HIV Staging'
      #We want to determine severe / moderate wasting based on today's ht/wt rather than depending on the user selection of such indicators
      yes_concept_id = Concept.find_by_name("Yes").id
      no_concept_id = Concept.find_by_name("No").id
      child_severe_wasting_concept = Concept.find_by_name('Severe unexplained wasting / malnutrition not responding to treatment(weight-for-height/ -age less than 70% or MUAC less than 11cm or oedema)')
      child_moderate_wasting_concept = Concept.find_by_name('Moderate unexplained wasting / malnutrition not responding to treatment (weight-for-height/ -age 70-79% or MUAC 11-12cm)')
      if patient.weight_for_height && patient.weight_for_age
        if (patient.weight_for_height >= 70 && patient.weight_for_height <= 79) || (patient.weight_for_age >= 70 && patient.weight_for_age <= 79)
          params[:observation]["select:#{child_moderate_wasting_concept.id}"] = yes_concept_id
        else
          params[:observation]["select:#{child_moderate_wasting_concept.id}"] = no_concept_id
        end
        if patient.weight_for_height < 70 || patient.weight_for_age < 70
          params[:observation]["select:#{child_severe_wasting_concept.id}"] = yes_concept_id
        else
          params[:observation]["select:#{child_severe_wasting_concept.id}"] = no_concept_id
        end
      end
    end

    encounter.parse_observations(params) # parse params and create observations from them
    encounter.save

    patient.arv_number= "#{Location.current_arv_code} #{params[:arv_number].to_i}" if params[:arv_number]

    @menu_params = ""

    #case encounter.type.name
    case encounter.name
      when "HIV Staging"
        self.staging(encounter,patient,params)
        unless patient.reason_for_art_eligibility.blank?
          PersonAttribute.create(patient.id,patient.reason_for_art_eligibility.name) 
        end  
        PersonAttribute.create(patient.id,patient.who_stage,"WHO stage") 
      when "ART Visit"
        self.art_followup(encounter,patient,params)
    end

    encounter.patient.reset_outcomes if encounter.name =~ /ART Visit|Give drugs|Update outcome/
    return "/patient/menu?" + @menu_params
  end


  def self.staging(encounter,patient,params)
    self.retrospective_staging(encounter,params)
    self.determine_hiv_wasting_syndrome(encounter) if not patient.child? #we no longer need to determine hiv wasting for children
  end
   
  def self.retrospective_staging(encounter,params)
    # Get all of the selected conditions into one array
    presumed_hiv_conditions = params["presumed_hiv_disease_conditions"].flatten.compact rescue nil #conditions    for kids under 17 mons with rapid test are collected here
    conditions = [1,2,3,4].collect{|stage_number| params["stage#{stage_number}"]}.flatten.compact
    conditions += presumed_hiv_conditions unless presumed_hiv_conditions.blank?
    yes = Concept.find_by_name("Yes")
    conditions.each{|concept_id|
      observation = encounter.add_observation(concept_id)
      observation.value_coded = yes.id
      observation.save
    }
  end
  
  def self.art_followup(encounter,patient,params)
		clinician_referral_id = Concept.find_by_name("Refer patient to clinician").id
		refer_to_clinician = params["observation"]["select:#{clinician_referral_id}"]
		@menu_params = "no_auto_load_forms=true" if refer_to_clinician.to_i == Concept.find_by_name("Yes").id unless refer_to_clinician.nil?
    # tablets
    concept_brought_to_clinic = Concept.find_by_name("Whole tablets remaining and brought to clinic")
    concept_not_brought_to_clinic = Concept.find_by_name("Whole tablets remaining but not brought to clinic")
    params["tablets"].each{|drug_id, location_amount|
      
      location_amount.each{|location,amount|
        if location == "at_clinic"
          observation = encounter.add_observation(concept_brought_to_clinic.id)
        else
          observation = encounter.add_observation(concept_not_brought_to_clinic.id)
        end
        observation.value_drug = drug_id
        if amount == 'Unknown'
          observation.value_numeric = nil
          observation.value_coded = Concept.find_by_name('Unknown').id
        else
          observation.value_numeric = amount
        end
        observation.save
      }
    } unless params["tablets"].nil?
    
    prescribed_dose = Concept.find_by_name("Prescribed dose")



   #_____________________________________________________________

   yes_concept_id = Concept.find(:first,:conditions => ["name=?","Yes"]).concept_id
   drug_concept_id = Concept.find(:first,:conditions => ["name=?","ARV regimen"]).concept_id
   recommended_dosage = Concept.find(:first,:conditions => ["name=?","Prescribe recommended dosage"]).concept_id
   prescribe_drugs=Hash.new()

   if !params["observation"]["select:#{drug_concept_id}"].blank? and  params["observation"]["select:#{drug_concept_id}"] != "Other"
     drug_concept_name = Concept.find(:first,:conditions => ["concept_id=?", params["observation"]["select:#{drug_concept_id}"].to_i]).name
     prescription = DrugOrder.recommended_art_prescription(patient.current_weight)[drug_concept_name]
     prescription.each{|recommended_presc|
       drug = Drug.find(recommended_presc.drug_inventory_id)
       prescribe_drugs[drug.name] = {"Morning" => "None", "Noon" => "None", "Evening" => "None", "Night" => "None"} if prescribe_drugs[drug.name].blank?
       prescribe_drugs[drug.name][recommended_presc.frequency] = recommended_presc.units.to_s 
     }
   else
        Drug.find(:all,:conditions =>["concept_id IS NOT NULL"]).each{|drug|
          ["Morning","Noon","Evening","Night"].each{|time|
            if !params["#{drug.name}_#{time}"].blank?  
              prescribe_drugs[drug.name] = {"Morning" => "None", "Noon" => "None", "Evening" => "None", "Night" => "None"} if prescribe_drugs[drug.name].blank?
              prescribe_drugs[drug.name][time] = params["#{drug.name}_#{time}"] 
            elsif params["#{drug.name}"] == "Yes"
              prescribe_drugs[drug.name] = {"Morning" => "None", "Noon" => "None", "Evening" => "None", "Night" => "None"} if prescribe_drugs[drug.name].blank?
              prescription = DrugOrder.recommended_art_prescription(patient.current_weight)[drug.concept.name]
              prescription.each{|recommended_presc|
                prescribe_drugs[drug.name][recommended_presc.frequency] = recommended_presc.units.to_s 
              }
            end  
      }
     }
   end
      
      
   prescribe_cpt = Concept.find(:first,:conditions => ["name=?","Prescribe Cotrimoxazole (CPT)"]).concept_id
   prescribe_cpt_ans = params["observation"]["select:#{prescribe_cpt}"].to_i rescue no_concept_id
   if prescribe_cpt_ans == yes_concept_id
     prescribe_drugs["Cotrimoxazole 480"] = {"Morning" => "1.0", "Noon" => "None", "Evening" => "1.0", "Night" => "None"}
   end 
       
#______________________________________________________________________
    prescribe_drugs.each{|drug_name, frequency_quantity|
      drug = Drug.find_by_name(drug_name)
      raise "Can't find #{drug_name} in drug table" if drug.nil?
      frequency_quantity.each{|frequency, quantity|
        next if frequency.blank? || quantity.blank?
        observation = encounter.add_observation(prescribed_dose.concept_id)
        observation.drug = drug
        observation.value_numeric = eval("1.0*" + self.validate_quantity(quantity)) rescue 0.0
        observation.value_text = frequency
        observation.save
      }
    } unless prescribe_drugs.blank?

      #DrugOrder.recommended_art_prescription(patient.current_weight)[regimen_string].each{|drug_order|
    return true  
  end

  def self.validate_quantity(quantity)
    return "0" if quantity.to_s == "None"
    return quantity.to_s unless quantity.to_s.include?("/")
    case quantity.gsub("(","").gsub(")","").strip
      when "1/4"
        return "0.25" 
      when "1/5"
        return "0.5" 
      when "3/4"
        return "0.75" 
      when "1 1/4"
        return "1.25" 
      when "1 1/2"
        return "1.5" 
      when "1 3/4"
        return "1.75" 
      when "1/3"
        return "0.3" 
    end 
  end


  def self.determine_hiv_wasting_syndrome(encounter)
    # HIV wasting syndrome (weight loss > 10% of body weight and either chronic fever or diarrhoea in the absence of concurrent illness)
    # Concepts needed for this section
    hiv_wasting_syndrome_concept = Concept.find_by_name("HIV wasting syndrome (severe weight loss + persistent fever or severe loss + chronic diarrhoea)")
# If there is already an hiv_wasting_syndrom observation then there is not need to run this code
    return unless encounter.observations.find_by_concept_id(hiv_wasting_syndrome_concept.id).empty?
    severe_weightloss_concept = Concept.find_by_name "Severe weight loss >10% and/or BMI <18.5kg/m(squared), unexplained"
    chronic_fever_concept = Concept.find_by_name "Fever, persistent unexplained (intermittent or constant, > 1 month)"
    chronic_diarrhoea_concept = Concept.find_by_name "Diarrhoea, chronic (>1 month) unexplained"
    yes_concept = Concept.find_by_name "Yes"


    has_severe_weightloss = false
    has_chronic_fever = false
    has_chronic_diarrhoea = false
    encounter.observations.each{|observation|
      has_severe_weightloss = true if observation.concept_id == severe_weightloss_concept.id and observation.value_coded == yes_concept.id
      has_chronic_fever = true if observation.concept_id == chronic_fever_concept.id and observation.value_coded == yes_concept.id
      has_chronic_diarrhoea = true if observation.concept_id == chronic_diarrhoea_concept.id and observation.value_coded == yes_concept.id
    }
    
    # calc hiv wasting syndrome
    hiv_wasting_syndrome_observation = encounter.add_observation(Concept.find_by_name("HIV wasting syndrome (severe weight loss + persistent fever or severe loss + chronic diarrhoea)").id)
    if has_severe_weightloss and (has_chronic_fever or has_chronic_diarrhoea)
      hiv_wasting_syndrome_observation.value_coded = yes_concept.id
    else
      hiv_wasting_syndrome_observation.value_coded = Concept.find_by_name("No").id
    end
    hiv_wasting_syndrome_observation.save

  end









#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



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
