require "enumerator"

class Patient < OpenMRS
  set_table_name "patient"
  set_primary_key "patient_id"

#------------------------------------------------------------------------------
# REFACTOR   
#------------------------------------------------------------------------------
# Everything above this line is good.  

	  has_many :observations, :foreign_key => :patient_id do
	    def find_by_concept_id(concept_id)
	      find(:all, :conditions => ["voided = 0 and concept_id = ?", concept_id])
	    end
	    def find_by_concept_name(concept_name)
	      find(:all, :conditions => ["voided = 0 and concept_id = ?", Concept.find_by_name(concept_name).id],:order => "obs_datetime ASC")
	    end
	    def find_first_by_concept_name(concept_name)
	      find(:first, :conditions => ["voided = 0 and concept_id = ?", Concept.find_by_name(concept_name).id], :order => "obs_datetime")
	    end
	    def find_last_by_concept_name(concept_name)
	      find(:first, :conditions => ["voided = 0 and concept_id = ?", Concept.find_by_name(concept_name).id], :order => "obs_datetime DESC")
	    end
	    
	    def find_by_concept_name_on_date(concept_name,date)
	      find(:all, :conditions => ["voided = 0 AND concept_id = ? AND DATE(obs_datetime) = ?", Concept.find_by_name(concept_name).id, date], :order => "obs_datetime")
	    end
	    def find_first_by_concept_name_on_date(concept_name,date)
	      find(:first, :conditions => ["voided = 0 and concept_id = ? AND DATE(obs_datetime) = ?", Concept.find_by_name(concept_name).id, date], :order => "obs_datetime")
	    end
	    def find_last_by_concept_name_on_date(concept_name,date)
	      find(:first, :conditions => ["voided = 0 and concept_id = ? AND DATE(obs_datetime) = ?", Concept.find_by_name(concept_name).id, date], :order => "obs_datetime DESC")
	    end
	    def find_first_by_concept_name_on_or_after_date(concept_name,date)
	      find(:first, :conditions => ["voided = 0 and concept_id = ? AND DATE(obs_datetime) >= ?", Concept.find_by_name(concept_name).id, date], :order => "obs_datetime")
	    end
	    def find_last_by_concept_name_on_or_before_date(concept_name,date)
	      find(:first, :conditions => ["voided = 0 and concept_id = ? AND DATE(obs_datetime) <= ?", Concept.find_by_name(concept_name).id, date], :order => "obs_datetime DESC")
	    end
	    
	    def find_last_by_concept_name_before_date(concept_name,date)
	      find(:first, :conditions => ["voided = 0 and concept_id = ? AND DATE(obs_datetime) < ?", Concept.find_by_name(concept_name).id, date], :order => "obs_datetime DESC")
	    end

	    def find_last_by_conditions(conditions)
	      # Remove voided observations
	      conditions[0] = "voided = 0 AND " + conditions[0]
	      find(:first, :conditions => conditions, :order => "obs_datetime DESC, date_created DESC")
	    end
	    def find_by_concept_name_with_result(concept_name, value_coded_concept_name)
	      find(:all, :conditions => ["voided = 0 and concept_id = ? AND value_coded = ?", Concept.find_by_name(concept_name).id, Concept.find_by_name(value_coded_concept_name).id], :order => "obs_datetime DESC")
	    end
	  end

	  has_many :patient_identifiers, :foreign_key => :patient_id, :dependent => :delete_all do
	    def find_first_by_identifier_type(identifier_type)
	      return find(:first, :conditions => ["patient_identifier.voided = 0 AND identifier_type = ?", identifier_type])
	    end
	  end

	  has_many :patient_names, :foreign_key => :patient_id, :dependent => :delete_all, :conditions => "patient_name.voided = 0"
	  has_many :notes, :foreign_key => :patient_id
	  has_many :patient_addresses, :foreign_key => :patient_id, :dependent => :delete_all
	  has_many :encounters, :foreign_key => :patient_id do
	  
	    def find_by_type_id(type_id)
	      find(:all, :conditions => ["encounter_type = ?", type_id])
	    end

	    def find_by_type_name(type_name)
	      encounter_type = EncounterType.find_by_name(type_name)
	      raise "Encounter type #{type_name} does not exist" if encounter_type.nil?
	      find(:all, :conditions => ["encounter_type = ?", EncounterType.find_by_name(type_name).id])
	    end

	    def find_by_date(encounter_date)
	      find(:all, :conditions => ["DATE(encounter_datetime) = DATE(?)", encounter_date])
	    end

	    def find_by_type_name_and_date(type_name, encounter_date)
	      find(:all, :conditions => ["DATE(encounter_datetime) = DATE(?) AND encounter_type = ?", encounter_date, EncounterType.find_by_name(type_name).id]) # Use the SQL DATE function to compare just the date part
	    end
	    
	    def find_by_type_name_before_date(type_name, encounter_date)
	      find(:all, :conditions => ["DATE(encounter_datetime) < DATE(?) AND encounter_type = ?", encounter_date, EncounterType.find_by_name(type_name).id]) # Use the SQL DATE function to compare just the date part
	    end

	    def find_first_by_type_name(type_name)
	       find(:first,:conditions => ["encounter_type = ?", EncounterType.find_by_name(type_name).id], :order => "encounter_datetime ASC, date_created ASC")
	    end

	    def find_last_by_type_name(type_name)
	       encounters = find(:all,:conditions => ["encounter_type = ?", EncounterType.find_by_name(type_name).id], :order => "encounter_datetime DESC, date_created DESC")
         encounters.delete_if{|e| e.voided?}
         encounters.first
	    end

			def find_all_by_conditions(conditions)
	      return find(:all, :conditions => conditions)
	    end

			def find_last_by_conditions(conditions)
	      return find(:first, :conditions => conditions, :order => "encounter_datetime DESC, date_created DESC")
	    end

			def last
	      return find(:first, :order => "encounter_datetime DESC, date_created DESC")
	    end

	  end

	  has_many :people, :foreign_key => :patient_id, :dependent => :delete_all
	  belongs_to :tribe, :foreign_key => :tribe_id
	  belongs_to :user, :foreign_key => :user_id
	  has_many :patient_programs, :foreign_key => :patient_id
	  has_many :programs, :through => :patient_programs

    def self.merge(patient_id, secondary_patient_id)
      patient = Patient.find(patient_id, :include => [:patient_identifiers, :patient_programs, :patient_names])
      secondary_patient = Patient.find(secondary_patient_id, :include => [:patient_identifiers, :patient_programs, :patient_names])
      ActiveRecord::Base.connection.execute("UPDATE person SET patient_id = #{patient_id} WHERE patient_id = #{secondary_patient_id}")
      ActiveRecord::Base.connection.execute("UPDATE patient_address SET patient_id = #{patient_id} WHERE patient_id = #{secondary_patient_id}")
      ActiveRecord::Base.connection.execute("UPDATE encounter SET patient_id = #{patient_id} WHERE patient_id = #{secondary_patient_id}")
      ActiveRecord::Base.connection.execute("UPDATE obs SET patient_id = #{patient_id} WHERE patient_id = #{secondary_patient_id}")
      ActiveRecord::Base.connection.execute("UPDATE note SET patient_id = #{patient_id} WHERE patient_id = #{secondary_patient_id}")
      secondary_patient.patient_identifiers.each {|r| 
        next if patient.patient_identifiers.map(&:identifier).include?(r.identifier)
        r.patient_id = patient_id
        r.save! 
      }
      ActiveRecord::Base.connection.execute("DELETE FROM patient_identifier WHERE patient_id = #{secondary_patient_id}")
      secondary_patient.patient_names.each {|r| 
        next if patient.patient_names.map{|pn| "#{pn.given_name} #{pn.family_name}"}.include?("#{r.given_name} #{r.family_name}")
        r.patient_id = patient_id
        r.save! 
      }
      ActiveRecord::Base.connection.execute("DELETE FROM patient_name WHERE patient_id = #{secondary_patient_id}")
      secondary_patient.patient_programs.each {|r| 
        next if patient.patient_programs.map(&:program_id).include?(r.program_id)
        r.patient_id = patient_id
        r.save! 
      }
      ActiveRecord::Base.connection.execute("DELETE FROM patient_program WHERE patient_id = #{secondary_patient_id}")
      Patient.delete(secondary_patient_id)
    end

	  def add_program_by_name(program_name)
	    self.add_programs([Program.find_by_name(program_name)])
	  end

	  def add_programs(programs)
	    #raise programs.to_yaml
	    programs.each{|program|
	      patient_program = PatientProgram.new
	      patient_program.patient_id = self.id
	      patient_program.program_id = program.program_id
	      patient_program.save
	    }
	  end

	  # Intersect the patient's programs and the user's programs to find out what program should be used to determine the next form
	  def available_programs (user = User.current_user)
	    #TODO why doesn't the above .program work???
	    programs = PatientProgram.find_all_by_patient_id(self.id).collect{|pp|pp.program}
	    available_programs = programs & user.current_programs

	#    if available_programs.length <= 0
	#      raise "Patient has no programs that the current user can provide services for.\n Patient programs: #{self.programs.collect{|p|p.name}.to_yaml}\n User programs: #{User.current_user.current_programs.collect{|p|p.name}.to_yaml}" 
	#    end
	    available_programs
	  end

	  def current_encounters(date = Date.today)
	    self.encounters.find(:all, :conditions => ["DATE(encounter_datetime) = DATE(?)", date], :order => "date_created DESC")
	  end

	  def last_encounter(date = Date.today)
	    # Find the last significant (non-barcode scan) encounter
	    encounter_types = ["HIV Reception", "Height/Weight", "HIV First visit", "ART Visit", "TB Reception", "HIV Staging", "General Reception"]
	    condition = encounter_types.collect{|encounter_type|
	      "encounter_type = #{EncounterType.find_by_name(encounter_type).id}"
	    }.join(" OR ")
	    self.encounters.find_last_by_conditions(["DATE(encounter_datetime) = DATE(?) AND (#{condition})", date])
	  end

    # Returns the name of the last patient encounter for a given day according to the 
    # patient flow regardless of the encounters' datetime
    # The order in which these encounter types are listed is different from that of next encounters
    def last_encounter_name_by_flow(date = Date.today)
      unless self.transfer_in_with_letter? 
        encounter_index_to_name = ["HIV Reception", "HIV First visit", "Height/Weight", "HIV Staging", "ART Visit", "Give drugs", "TB Reception", "General Reception"]
        encounter_name_to_index = {'HIV Reception' => 0,
                                   'HIV First visit' => 1,
                                   'Height/Weight' => 2, 
                                   'HIV Staging' => 3,
                                   'ART Visit' => 4, 
                                   'Give Drugs' => 5,
                                   'TB Reception' => 6,
                                   'General Reception' => 7
                                  }
      else
        encounter_index_to_name = ["HIV Reception", "HIV First visit", "HIV Staging", "Height/Weight", "ART Visit", "Give drugs", "TB Reception", "General Reception"]
        encounter_name_to_index = {'HIV Reception' => 0,
                                   'HIV First visit' => 1,
                                   'HIV Staging' => 2,
                                   'Height/Weight' => 3, 
                                   'ART Visit' => 4, 
                                   'Give Drugs' => 5,
                                   'TB Reception' => 6,
                                   'General Reception' => 7
                                  }
      end
      encounter_order_numbers = []
      self.encounters.find_by_date(date).each{|encounter| 
        order_number = encounter_name_to_index[encounter.name]
        encounter_order_numbers << order_number if order_number
      }
      encounter_index_to_name[encounter_order_numbers.max]
    end

    # Returns the last patient encounter for a given day according to the 
    # patient flow regardless of the encounters' datetime
    def last_encounter_by_flow(date = Date.today)
      last_encounter_name = self.last_encounter_name_by_flow(date)
      last_encounter_type = EncounterType.find_by_name(last_encounter_name)
      return self.encounters.find_last_by_conditions("encounter_type = #{last_encounter_type.id}") if last_encounter_type
      return nil
    end

	  def next_forms(date = Date.today)
	    #return if self.outcome != Concept.find_by_name("On ART") and self.outcome != Concept.find_by_name('Defaulter')
	    return unless self.outcome.name =~ /On ART|Defaulter/ 
	    
	    last_encounter = self.last_encounter(date)

	    next_encounter_type_names = Array.new
	    if last_encounter.blank?
	      program_names = User.current_user.current_programs.collect{|program|program.name}
	      next_encounter_type_names << "HIV Reception" if program_names.include?("HIV")
	      next_encounter_type_names << "TB Reception" if program_names.include?("TB")
	      next_encounter_type_names << "General Reception" if User.current_user.activities.include?('General Reception')
	    else
	      last_encounter = self.last_encounter_by_flow(date)
	      next_encounter_type_names = last_encounter.next_encounter_types(self.available_programs(User.current_user))
	    end

      # if patient is not present - always skip vitals
      if next_encounter_type_names.include?("Height/Weight")
        patient_present = self.observations.find_last_by_concept_name_on_date("Patient present",date)
        if patient_present and patient_present.value_coded != Concept.find_by_name("Yes").id
          next_encounter_type_names.delete("Height/Weight")
          next_encounter_type_names << "ART Visit"
        end
      end

      # Skip HIV first visit if they have already done it
	    if next_encounter_type_names.include?("HIV First visit")
	      next_encounter_type_names.delete("HIV First visit") unless self.encounters.find_by_type_name("HIV First visit").empty?
	    end

	    if self.reason_for_art_eligibility.nil?
	      next_encounter_type_names.delete("ART Visit")
	    else
	      next_encounter_type_names.delete("HIV Staging")
	    end


	    next_forms = Array.new
	    # If there is more than one encounter_type take the first one
	    return [] if next_encounter_type_names.empty?
	    next_encounter_type_name = next_encounter_type_names.first
	    next_encounter_type = EncounterType.find_by_name(next_encounter_type_name)
	    raise "No encounter type named #{next_encounter_type_name}" if next_encounter_type.nil?
	    forms_for_encounter = Form.find_all_by_encounter_type(next_encounter_type.id)
	    next_forms <<  forms_for_encounter

	    next_forms = next_forms.flatten.compact


	    # Filter out forms that are age dependent and don't match the current patient
      puts next_forms.map(&:name)
	    next_forms.delete_if{|form|
	      form.uri.match(/adult|child/i) and not form.uri.match(/#{self.adult_or_child}/i)
	    }
	# If they are a transfer in with a letter we want the receptionist to copy the staging info using the retrospective staging form
	    next_forms.each{|form|
	      if form.name == "HIV Staging"
   puts form.version
		if self.transfer_in_with_letter?
		  next_forms.delete(form) unless form.version == "multi_select"
		else
		  next_forms.delete(form) unless form.version == GlobalProperty.find_by_property("staging_interface").property_value
		end
	      end
	    }

	    return next_forms
	    
	  end

	  def current_weight(date = Date.today)
	    current_weight_observation = self.observations.find_last_by_concept_name_on_or_before_date("Weight",date)
	    return current_weight_observation.value_numeric unless current_weight_observation.nil?
	  end
	  
	  def current_visit_weight(date = Date.today)
	    current_weight_observation = self.observations.find_last_by_concept_name_on_date("Weight",date)
	    return current_weight_observation.value_numeric unless current_weight_observation.nil?
	  end

	  def previous_weight(date = Date.today)
	    previous_weight_observation = self.observations.find_last_by_concept_name_before_date("Weight",date)
	    return previous_weight_observation.value_numeric unless previous_weight_observation.nil?
	  end

	  def percent_weight_changed(start_date, end_date = Date.today)
	    start_weight = self.observations.find_first_by_concept_name_on_or_after_date("Weight", start_date).value_numeric rescue nil
	    end_weight = self.current_weight(end_date) rescue nil
	    return nil  if end_weight.blank? || start_weight.blank?
	    return (end_weight - start_weight)/start_weight
	  end
	  
	  def current_height(date = Date.today)
	    current_height_observation = self.observations.find_last_by_concept_name_on_or_before_date("Height",date)
	    return current_height_observation.value_numeric unless current_height_observation.nil?
	  end
	  
	  def previous_height(date = Date.today)
	    previous_height_observation = self.observations.find_last_by_concept_name_before_date("Height",date)
	    return previous_height_observation.value_numeric unless previous_height_observation.nil?
	  end

	  def current_bmi(date = Date.today)
	    current_weight = self.current_weight(date)
	    current_height = self.current_height(date)
	    return (current_weight/(current_height**2)*10000) unless current_weight.nil? or current_height.nil?
	  end

	  def art_therapeutic_feeding_message(date = Date.today)
	    bmi = self.current_bmi(date) 
	    return if bmi.nil?
	    if (bmi > 18.5)
	      return ""
	    elsif (bmi > 17.0)
	      return "Patient needs counseling due to their low bmi"
	    else
	      return "Eligibile for therapeutic feeding"
	    end
	  end

	  def outcome(on_date = Date.today)
			outcome_concept_id = Concept.find_by_name("Outcome").id
			last_outcome = self.observations.find_last_by_conditions(["concept_id = ? AND DATE(obs_datetime) <= ?", outcome_concept_id, Date.today])
	    if last_outcome.nil? 
	      return Concept.find_by_name("On ART")
	    else
	      return last_outcome.answer_concept
	    end
	  end
	 
	  # TODO replace all of these outcome methods with just one
	  # This one returns strings - probably better to do concepts like above method 
	  def outcome_status
      last_outcome = self.observations.find_last_by_concept_name("Outcome")
	    return outcome =  last_outcome.nil? ? "Alive and on ART" : Concept.find(last_outcome.value_coded).name
	  end
	  
	  def cohort_outcome_status(start_date=nil, end_date=nil)
			start_date = Encounter.find(:first, :order => "encounter_datetime").encounter_datetime.to_date if start_date.nil?
			end_date = Date.today if end_date.nil?

			outcome_concept_id = Concept.find_by_name("Outcome").id
			last_outcome_concept = self.observations.find_last_by_conditions(["concept_id = ? AND DATE(obs_datetime) >= ? AND DATE(obs_datetime) <= ?", outcome_concept_id, start_date, end_date])
	    outcome =  last_outcome_concept.nil? ? "Alive and on ART" : Concept.find(last_outcome_concept.value_coded).name
	    return outcome
	  end

	  def continue_treatment_at_current_clinic(date)
	     concept_name="Continue treatment at current clinic"
	     date=date.to_date
	     patient_observations = Observation.find(:all,:conditions => ["concept_id=? and patient_id=? and Date(obs.obs_datetime)=?",(Concept.find_by_name(concept_name).id),self.patient_id,date],:order=>"obs.obs_datetime desc")
	     return nil if patient_observations.blank?
	     return patient_observations.first.obs_datetime.to_date
	  end
	  
## DRUGS
	  def drug_orders
	    self.encounters.find_by_type_name("Give drugs").collect{|dispensation_encounter|
	      next if dispensation_encounter.voided?
	      dispensation_encounter.orders.collect{|order|
		order.drug_orders
	      }
	    }.flatten.compact
	  end
	  
## DRUGS
	  def drug_orders_by_drug_name(drug_name)
	    #TODO needs optimization
	    self.encounters.find_by_type_name("Give drugs").collect{|dispensation_encounter|
	      next if dispensation_encounter.voided?
	      dispensation_encounter.orders.collect{|order|
		order.drug_orders.collect{|drug_order|
		  drug_order if drug_order.drug.name == drug_name
		}
	      }
	    }.flatten.compact
	  end
	  
## DRUGS
	  def drug_orders_for_date(date)
	    self.encounters.find_by_type_name_and_date("Give drugs", date).collect{|dispensation_encounter|
	      next if dispensation_encounter.voided?
	      dispensation_encounter.orders.collect{|order|
		      order.drug_orders
	      }
	    }.flatten.compact
	  end
	 
## DRUGS
	  # This should only return drug orders for the most recent date 
	  def previous_art_drug_orders(date = Date.today)
	    
	#    last_dispensation_encounters = self.encounters.find_all_by_type_name_from_previous_visit("Give drugs", date)

	    last_dispensation_encounters = self.encounters.find(
	      :all, 
	      :conditions => ["Encounter_type = ? AND DATE(encounter_datetime) <= DATE(?)", EncounterType.find_by_name("Give drugs").id, date],
	      :order => "encounter_datetime DESC, date_created DESC LIMIT 30"
	    )
	    return nil if last_dispensation_encounters.empty?
	    last_orders = last_dispensation_encounters.collect{|encounter|encounter.orders}.compact.flatten
	    return nil if last_orders.empty?
	    drug_orders = last_orders.collect{|order|
	      next if order.voided?
	      order.drug_orders
	    }.flatten.compact
	    drug_orders.delete_if{|drug_order| not drug_order.arv?}
	    drug_orders_by_date = Hash.new()
	    drug_orders.each{|drug_order|
	      drug_orders_by_date[drug_order.date] = [] if drug_orders_by_date[drug_order.date].nil?
	      drug_orders_by_date[drug_order.date] << drug_order
	    }
	    previous_art_date = drug_orders_by_date.keys.sort.last
	    return drug_orders_by_date[previous_art_date]
	#    return drug_orders

	  end
		
## DRUGS
	  def cohort_last_art_regimen(start_date=nil, end_date=nil)
			start_date = Encounter.find(:first, :order => "encounter_datetime").encounter_datetime.to_date if start_date.nil?
			end_date = Date.today if end_date.nil?
			
## OPTIMIZE, really, this is ONLY used for cohort and we should be able to use the big set of encounter/regimen names
      dispensation_type_id = EncounterType.find_by_name("Give drugs").id
	    #self.encounters.each {|encounter|
	    self.encounters.find(:all, 
                           :conditions => ['encounter_type = ? AND encounter_datetime >= ? AND encounter_datetime <= ?',
                                           dispensation_type_id, start_date, end_date],
                           :order => 'encounter_datetime DESC'
                          ).each {|encounter|
        #next unless encounter.encounter_datetime.to_date >= start_date and encounter.encounter_datetime.to_date < end_date && encounter.encounter_type == dispensation_type_id
	      regimen = encounter.regimen
	      return regimen if regimen
	    }
	    return nil
		end

    # returns short code of the most recent art drugs received
    # Coded to add regimen break down to cohort
    def cohort_last_art_drug_code(start_date=nil, end_date=nil)
      latest_drugs_date =  PatientDispensationAndPrescription.find(:first, :order => 'visit_date DESC', :conditions => ['patient_id = ? AND visit_date < ?', self.id, end_date]).visit_date
      latest_drugs =  PatientDispensationAndPrescription.find(:all, :order => 'visit_date DESC', :conditions => ['patient_id = ? AND visit_date = ?', self.id, latest_drugs_date]).map(&:drug)

      latest_drugs.map{|drug| drug.concept.name rescue ' '}.uniq.sort.join(' ')
    end
## DRUGS
	  # returns the most recent guardian
	  def art_guardian  
	    guardian_type = RelationshipType.find_by_name("ART Guardian")
	    # each patient should have 1 corresponding person record
	    person = self.people[0]
	    begin
	      rel = Relationship.find(:first, :conditions => ["voided = 0 AND relationship = ? AND person_id = ?", guardian_type.id, person.id], :order => "date_created DESC") unless person.nil?
	      rel = rel.relative.patient unless person.nil?
	    rescue
	      return nil
	    end
	    return rel
	  end
	  
	  def art_guardian=(guardian)
	    raise "Guardian and patient can not be the same person" if self == guardian
	    
	    person = Person.find_or_create_by_patient_id(self.id)
	    guardian_person = Person.find_or_create_by_patient_id(guardian.id)
	    guardian_type = RelationshipType.find_by_name("ART Guardian")
	    
	    guardian_relationship = Relationship.new
	    guardian_relationship.person_id = person.id
	    guardian_relationship.relative_id = guardian_person.id
	    guardian_relationship.relationship = guardian_type.id
	    guardian_relationship.save
	  end

	  def create_guardian(first_name,last_name,sex)
	   guardian = Patient.new()
	   guardian.save
	   guardian.gender = sex
	   guardian.set_name(first_name,last_name)
	   guardian.save
	   self.art_guardian=(guardian)
	  end
	   
	  def art_guardian_of
	   self.people.collect{|people| people.related_from.collect{|p| p.person.patient.name unless p.attributes["voided"] == true }}.flatten.compact
	  end
	  
	  def name
	    "#{self.given_name} #{self.family_name}"
	  end
	  
	  def name_with_id
	    name + " " + self.print_national_id 
	  end

	  def age(today = Date.today)
	    #((Time.now - self.birthdate.to_time)/1.year).floor
	    # Replaced by Jeff's code which better accounts for leap years

	    return nil if self.birthdate.nil?

	    patient_age = (today.year - self.birthdate.year) + ((today.month - self.birthdate.month) + ((today.day - self.birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)
	   
	    birth_date=self.birthdate
	    estimate=self.birthdate_estimated
	    if birth_date.month == 7 and birth_date.day == 1 and estimate==true and Time.now.month < birth_date.month and self.date_created.year == Time.now.year
	       return patient_age + 1
	    else
	       return patient_age
	    end     
	  end

	  def age=(age)
	    age = age.to_i
	    patient_estimated_birthyear = Date.today.year - age
	    patient_estimated_birthmonth = 7
	    patient_estimated_birthday = 1
	    self.birthdate = Date.new(patient_estimated_birthyear, patient_estimated_birthmonth, patient_estimated_birthday)
	    self.birthdate_estimated = true
	    self.save
	  end
	  
	  def age_in_months
	    ((Time.now - self.birthdate.to_time)/1.month).floor
	  end

	  def child?
	    return self.age <= 14 unless self.age.nil?
      return false
	  end

    def adult?
      return !self.child?
    end

	  def adult_or_child
	    self.child? ? "child" : "adult"
	  end

	  def age_at_initiation
	    initiation_date = self.date_started_art
	    return self.age(initiation_date) unless initiation_date.nil?
	  end

	  def child_at_initiation?
	    age_at_initiation = self.age_at_initiation
	    return age_at_initiation <= 14 unless age_at_initiation.nil?
	  end

    # The only time this is called is with no params... it is always first line, can we kill the param?
	  def date_started_art(regimen_type = "ARV First line regimen")
      @@date_started_art ||= Hash.new
      @@date_started_art[self.patient_id] ||= Hash.new
      return @@date_started_art[self.patient_id][regimen_type] if @@date_started_art[self.patient_id].has_key?(regimen_type)
	    # handle transfer IN
	    if self.transfer_in?
        @@date_started_art[self.patient_id][regimen_type] = self.encounters.find_last_by_type_name("HIV First visit").encounter_datetime
        return @@date_started_art[self.patient_id][regimen_type]
      end
      
      arv_dispensing_dates = []
      dispensation_type_id = EncounterType.find_by_name("Give drugs").id
	    self.encounters.each{|encounter|
        next unless encounter.encounter_type == dispensation_type_id
        unless Encounter.dispensation_encounter_regimen_names.blank?
    		  arv_dispensing_dates << encounter.encounter_datetime if Encounter.dispensation_encounter_regimen_names[encounter.encounter_id] == regimen_type        
        else  
          regimen_concept = DrugOrder.drug_orders_to_regimen(encounter.drug_orders)
    		  arv_dispensing_dates << encounter.encounter_datetime if regimen_concept && regimen_concept.name == regimen_type
	      end
	    }     
      # If there are no dispensing dates, try to use the Date of ART Initiation if available
      nil      
	    @@date_started_art[self.patient_id][regimen_type] = arv_dispensing_dates.sort.first unless arv_dispensing_dates.nil?
      @@date_started_art[self.patient_id][regimen_type] unless arv_dispensing_dates.nil?
	  end


	  def get_identifier(identifier)
	    identifier_list = self.patient_identifiers.collect{|patient_identifier| 
	      patient_identifier.identifier if patient_identifier.type.name == identifier}.compact 
	    
	    return identifier_list[0] if identifier_list.length == 1
	    return identifier_list
	  end

	  def set_first_name=(first_name)
	    patient_names = self.patient_names
	    patient_names = PatientName.new if patient_names.empty? || patient_names.nil?
	    patient_names.given_name = first_name
	    patient_names.save
	  end

	  def first_name
	    return given_name
	  end

	  def given_name
	    self.patient_names.last.given_name unless self.patient_names.blank?
	  end

	  def set_name(first_name,last_name)
	    patientname = PatientName.new()
	    patientname.given_name = first_name
	    patientname.family_name = last_name
	    patientname.patient = self
	    patientname.save
	  end

	  def last_name
	    return family_name
	  end
	  
	  def family_name
	    self.patient_names.last.family_name unless self.patient_names.blank?
	  end

	  def update_name!(name, reason)
	    self.patient_names[0].void!(reason) unless self.patient_names[0].nil?    
	    self.patient_names << name
	    self.patient_names(true)
	  end

	  def other_names
	    name=self.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("Other name").id)
	    return nil if name.nil? or name.identifier==""
	    return name.identifier
	  end  
	  def filing_number
	    filing_number=self.patient_identifiers.find_first_by_identifier_type(PatientIdentifierType.find_by_name("Filing number").id)
	    filingnumber = filing_number.identifier unless filing_number.voided  rescue nil
	    return filingnumber unless filingnumber.blank?
	    return self.archive_filing_number
	  end
	  
	  def archive_filing_number
	    filing_number=self.patient_identifiers.find_first_by_identifier_type(PatientIdentifierType.find_by_name("Archived filing number").id) rescue nil
	    filingnumber = filing_number.identifier unless filing_number.voided  rescue nil
	    return filingnumber unless filingnumber.blank?
	  end
	  
	  def patient_to_be_archived
	   archive_identifier_type = PatientIdentifierType.find_by_name("Archived filing number")
	   active_identifier_type = PatientIdentifierType.find_by_name("Filing number")
	   active_filing_number = self.filing_number rescue nil
	   return nil if active_filing_number.blank?
	   archive_filing_number = PatientIdentifier.find(:first,:conditions=>["voided=1 and identifier_type=? and identifier=?",active_identifier_type.id,active_filing_number],:order=>"date_created desc").patient rescue nil
	   return archive_filing_number unless archive_filing_number.blank?
	  end

	  def archived_patient_old_active_filing_number
	   active_identifier_type = PatientIdentifierType.find_by_name("Filing number")
	   return PatientIdentifier.find(:first,:conditions=>["voided=1 and patient_id=? and identifier_type=?",self.id,active_identifier_type.id],:order=>"date_created desc").identifier rescue nil
	  end
	  
	  def archived_patient_old_dormant_filing_number
	   dormant_identifier_type = PatientIdentifierType.find_by_name("Archived filing number")
	   return PatientIdentifier.find(:first,:conditions=>["voided=1 and patient_id=? and identifier_type=?",self.id,dormant_identifier_type.id],:order=>"date_created desc").identifier rescue nil
	  end
	  
	  def self.printing_filing_number_label(number=nil)
	   return number[5..5] + " " + number[6..7] + " " + number[8..-1] unless number.nil?
	  end

	  def hiv_patient?
	    return self.programs.collect{|program|program.name}.include?("HIV")
	  end

	  def art_patient?
	    # TODO - this does not necessarily mean they are on ART
	    return self.hiv_patient?
	  end
	  
	  def ARV_national_id
	    begin
	      self.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("Arv national id").id, :conditions => ['voided = ?', 0]).identifier 
	    rescue
	     return nil
	   end
	  end

	  def arv_number
	    self.ARV_national_id
	  end

	  def arv_number=(value)
	    arv_number_type = PatientIdentifierType.find_by_name('Arv national id')
			prif=value.match(/(.*)[A-Z]/i)[0] rescue Location.current_arv_code
	    number=value.match(/[0-9](.*)/i)[0]
			PatientIdentifier.update(self.id, "#{prif} #{number}", arv_number_type.id, "Update ARV Number")
	  end

	  def self.find_by_arvnumber(number)
	   patient = nil
     match = number.match(/([a-zA-Z]+) *(\d+)/)
     raise "It appears you have not entered the ARV code for the Location" unless match
	   (arv_header, arv_number) = match[1..2]
	   unless arv_header.blank? and arv_number.blank?
	     identifier = PatientIdentifier.find(:all, :conditions => ["identifier= ?", arv_header + " " + arv_number.to_i.to_s])  
	     patient_id = identifier.first.patient_id unless identifier.blank?
	     patient = Patient.find(patient_id) unless patient_id.blank?
	     if patient.blank?
	      identifier = PatientIdentifier.find(:all, :conditions => ["identifier= ?", arv_header + arv_number.to_i.to_s])  
	      patient_id = identifier.first.patient_id unless identifier.blank?
	      patient = Patient.find(patient_id) unless patient_id.blank?
	     end
	     patient unless patient.nil? or patient.voided
	   end
	  end

	  def national_id
	    national_id = self.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id)
	    national_id.identifier unless national_id.nil?
	  end

	  def person_address
	    address = self.patient_addresses
	    address.last.city_village unless address.blank?
	  end 
	  
	  def print_national_id
	    national_id = self.national_id
	    national_id[0..4] + "-" + national_id[5..8] + "-" + national_id[9..-1] unless national_id.nil?
	  end
	  
	  def mastercard
	    Mastercard.new(self)
	  end
	  
	  def birthdate_for_printing
	    birthdate = self.birthdate
	    if birthdate_estimated
	      if birthdate.day==1 and birthdate.month==7
		birth_date_string = birthdate.strftime("??/???/%Y")
	      elsif birthdate.day==15 
		birth_date_string = birthdate.strftime("??/%b/%Y")
	      end
	    else
	      birth_date_string = birthdate.strftime("%d/%b/%Y")
	    end
	    birth_date_string
	  end
	  
	  def art_initial_staging_conditions
	    staging_observations = self.encounters.find_by_type_name("HIV Staging").collect{|e|e.observations unless e.voided?}.flatten.compact rescue nil
	    #puts staging_observations.collect{|so|so.to_short_s + "  " + ".........."}
	    staging_observations.collect{|obs|obs.concept.to_short_s if obs.value_coded == Concept.find_by_name("Yes").id}.compact rescue nil
	  end

	  def who_stage
	    # calc who stage
	    yes_concept = Concept.find_by_name "Yes"
	    adult_or_peds = self.child? ? "peds" : "adult"
	    calculated_stage = 1 # Everyone is supposed to be HIV positive so start them at 1

	    staging_observations = self.encounters.find_by_type_name("HIV Staging").collect{|e|e.observations unless e.voided?}.flatten.compact

	    # loop through each of the stage defining conditions starting with the 
	    # the highest stages
	    4.downto(2){|stage_number|
	      Concept.find_by_name("WHO stage #{stage_number} #{adult_or_peds}").concepts.each{|concept|
		      break if calculated_stage > 1 # stop if we have found one already
		      staging_observations.each{|observation|
		      next unless observation.value_coded == yes_concept.id
		        if observation.concept_id == concept.id
		          calculated_stage = stage_number
		          break
		        end
		     } 
	      }
	    }
	    calculated_stage
	  end

	  def reason_for_art_eligibility
	    # If stage 3 or 4, that is the reason. Otherwise must have CD4 < 250 or lymphocyte count < 1200

	    who_stage = self.who_stage

	    if(who_stage >= 3)
	      adult_or_peds = self.child? ? "peds" : "adult"
	      return Concept.find_by_name("WHO stage #{who_stage} #{adult_or_peds}")
	    else
	# check for CD4 observation below 250 TODO what about children CD4 Percentage?
	      #low_cd4_count = !self.observations.find(:first, :conditions => ["value_numeric <= ? AND concept_id = ?",250, Concept.find_by_name("CD4 count").id]).nil?
        low_cd4_count = self.observations.find(:first,:conditions => ["(value_numeric <= ? AND concept_id = ?) OR (concept_id = ? and value_coded = ?)",250, Concept.find_by_name("CD4 count").id, Concept.find_by_name("CD4 Count < 250").id, (Concept.find_by_name("Yes").id rescue 3)]) != nil

	      return  Concept.find_by_name("CD4 count < 250") if low_cd4_count
	# check for lymphocyte observation below 1200
	      if self.child?
		# table from ART guidelines, threshold defined as severe by Tony Harries after inquiry from Mike to Mindy
		# For example: <1 year requires less than 4000 to be eligible
		thresholds = {
		  0=>4000, 1=>4000, 2=>4000, 
		  3=>3000, 4=>3000, 
		  5=>2500, 
		  6=>2000, 7=>2000, 8=>2000, 9=>2000, 10=>2000, 11=>2000, 12=>2000, 13=>2000, 14=>2000, 15=>2000
		}
		low_lymphocyte_count = self.observations.find(:first, :conditions => ["value_numeric <= ? AND concept_id = ?",thresholds[self.age], Concept.find_by_name("Lymphocyte count").id]).nil?
	      else
		low_lymphocyte_count = self.observations.find(:first, :conditions => ["value_numeric <= ? AND concept_id = ?",1200, Concept.find_by_name("Lymphocyte count").id]).nil?
	      end

	      return reason_for_starting = Concept.find_by_name("Lymphocyte count below threshold with WHO stage 2") if low_lymphocyte_count and who_stage >= 2
	    end
	    return nil
	  end

## DRUGS
	  def date_last_art_prescription_is_finished(from_date = Date.today)
	    #Find last drug order
	    last_10_give_drugs_encounters = self.encounters.find(:all, :conditions => ["encounter_type = ? AND encounter_datetime < ?", EncounterType.find_by_name("Give drugs").id, from_date], :limit => 10, :order => "encounter_datetime DESC, date_created DESC")
	    last_art_encounter = nil
	    last_10_give_drugs_encounters.each{|drug_encounter|
	      if drug_encounter.arv_given?
		last_art_encounter = drug_encounter
		break
	      end
	    }
	    return nil if last_art_encounter.nil?
	    # Find when they needed to come back to be adherent
	    dates_of_return_if_adherent = Array.new
	    last_art_encounter.orders.each{|order|
	      order.drug_orders.each{|drug_order|
		      dates_of_return_if_adherent << drug_order.date_of_return_if_adherent(from_date)
	      }
	    }
	    # If there are multiple values return the first
	    return dates_of_return_if_adherent.sort.first
	  end

	  # Use this when searching for ART patients
	  # use exclude_outcomes to remove dead patients, transfer outs, etc
	  def self.art_patients(options = nil)
	    #TODO make this efficient
	    #
	    # Get all patients in the HIV program
	    patients = Program.find_by_name("HIV").patients
	    raise "Can not both exclude and include outcomes" if options[:include_outcomes] and options[:exclude_outcomes] unless options.nil?

	    # Remove any patients who have not had an ART visit
	    patients.delete_if{|patient|
	      patient.encounters.find_first_by_type_name("ART visit").nil?
	    }

	    return patients if options.nil?

	    if options[:include_outcomes]
	      patients.delete_if{|patient|
		not options[:include_outcomes].include?(patient.outcome)
	      }
	    elsif options[:exclude_outcomes]
	      patients.delete_if{|patient|
		options[:exclude_outcomes].include?(patient.outcome)
	      }
	    end

	    return patients

	  end

    # CRON!
	  def self.update_defaulters(date = Date.today)
	    outcome_concept = Concept.find_by_name("Outcome")
	    defaulter_concept = Concept.find_by_name("Defaulter")
	    defaulters_added_count = 0
	    Patient.art_patients(:include_outcomes => [Concept.find_by_name("On ART")]).each{|patient|
	      if patient.defaulter?(date)

		#puts "Adding defaulter observation on #{date.to_s} to #{patient.name}"

		observation = Observation.new
		observation.patient = patient
		observation.concept_id = outcome_concept.id
		observation.value_coded = defaulter_concept.id
		observation.encounter = nil
		observation.obs_datetime = date
    observation.creator = User.current_user.id rescue User.find(:first).id 
		observation.save or raise "#{observation.errors}"
		defaulters_added_count += 1
	      end
	    }
	    return defaulters_added_count
	  end

	  # MOH defines a defaulter as someone who has not showed up 2 months after their drugs have run out
	  def defaulter?(from_date = Date.today, number_missed_days_required_to_be_defaulter = 60)
	    outcome = self.outcome(from_date).name
	    if outcome.match(/Dead|Transfer/)
	      return false
	    elsif outcome == "Defaulter"
	      return true
	    end
	    date_last_art_prescription_is_finished = self.date_of_return_if_adherent(from_date) #self.date_last_art_prescription_is_finished
	    date_last_art_prescription_is_finished = from_date if date_last_art_prescription_is_finished.nil?
	    return true if date_last_art_prescription_is_finished.to_date + number_missed_days_required_to_be_defaulter < from_date.to_date
	    return false
	  end

	  def set_transfer_in(status, date)
	    return if status.nil?
	    hiv_first_visit = self.encounters.find_first_by_type_name("HIV First visit")
	    if hiv_first_visit.blank?
	      hiv_first_visit = Encounter.new
	      hiv_first_visit.patient = self
	      hiv_first_visit.type = EncounterType.find_by_name("HIV First visit")
	      hiv_first_visit.encounter_datetime = date
	      hiv_first_visit.provider_id = User.current_user.id
	      hiv_first_visit.save
	    end

	    yes_no="No" if status == false
	    yes_no="Yes" if status == true
	    ever_received_art = Observation.new
	    ever_received_art.encounter = hiv_first_visit
	    ever_received_art.patient = self
	    ever_received_art.concept = Concept.find_by_name("Ever received ART")
	    ever_received_art.value_coded = Concept.find_by_name(yes_no).id
	    ever_received_art.obs_datetime = date
	    ever_received_art.save

	    ever_registered_at_art_clinic = Observation.new
	    ever_registered_at_art_clinic.encounter = hiv_first_visit
	    ever_registered_at_art_clinic.patient = self
	    ever_registered_at_art_clinic.concept = Concept.find_by_name("Ever registered at ART clinic")
	    ever_registered_at_art_clinic.value_coded = Concept.find_by_name(yes_no).id
	    ever_registered_at_art_clinic.obs_datetime = date
	    ever_registered_at_art_clinic.save
	  end

	  def transfer_in?
	    return false unless self.hiv_patient?
	    hiv_first_visit = self.encounters.find_first_by_type_name("HIV First visit")
	    return false if hiv_first_visit.blank?
	    #return false if  hiv_first_visit.observations.find_last_by_concept_name("Ever received ART").nil? or  hiv_first_visit.observations.find_last_by_concept_name("Ever registered at ART clinic").blank?
	    return false if hiv_first_visit.observations.find_last_by_concept_name("Ever registered at ART clinic").blank?
	    yes_concept = Concept.find_by_name("Yes")
	    #return true if hiv_first_visit.observations.find_last_by_concept_name("Ever received ART").answer_concept == yes_concept and hiv_first_visit.observations.find_last_by_concept_name("Ever registered at ART clinic").answer_concept == yes_concept
	    return true if hiv_first_visit.observations.find_last_by_concept_name("Ever registered at ART clinic").answer_concept == yes_concept
	    return false
	  end

	  def transfer_in_with_letter?
	    return false unless transfer_in?
	    hiv_first_visit = self.encounters.find_first_by_type_name("HIV First visit")
	    return false if hiv_first_visit.observations.find_last_by_concept_name("Has transfer letter").nil? 
	    yes_concept = Concept.find_by_name("Yes")
	    has_letter = (hiv_first_visit.observations.find_last_by_concept_name("Has transfer letter").answer_concept == yes_concept)
	    return has_letter
	  end


	  def previous_art_visit_encounters(date = Date.today)
	    return self.encounters.find(:all, :conditions => ["encounter_type = ? AND DATE(encounter_datetime) <= DATE(?)",EncounterType.find_by_name("ART Visit").id, date],  :order => "encounter_datetime DESC")
	  end

	  def art_visit_encounters(date = Date.today)
	    return self.encounters.find(:all, :conditions => ["encounter_type = ? AND DATE(encounter_datetime) = DATE(?)",EncounterType.find_by_name("ART Visit").id, date],  :order => "encounter_datetime DESC")
	  end

## DRUGS
	  def prescriptions(date = Date.today)
	    prescriptions = Array.new
	    art_visit_encounters(date).each{|followup_encounter|
	      prescriptions << followup_encounter.to_prescriptions
	    }
	    return prescriptions.flatten.compact
	  end

## DRUGS
	  def art_quantities_including_amount_remaining_after_previous_visit(from_date)
	    drug_orders = self.previous_art_drug_orders(from_date)
	    return nil if drug_orders.nil? or drug_orders.empty?
	    quantity_by_drug = Hash.new(0)
	    quantity_counted_by_drug = Hash.new(0)
	    drug_orders.each{|drug_order|
	#      puts drug_order.drug.name
	#      puts drug_order.quantity
	#      puts
	      quantity_by_drug[drug_order.drug] += drug_order.quantity
	      quantity_counted_by_drug[drug_order.drug] = drug_order.quantity_remaining_from_last_order
	    }
	    total_quantity_available_by_drug = Hash.new(0)
	    quantity_by_drug.each{|drug, quantity|
	      total_quantity_available_by_drug[drug] = quantity + quantity_counted_by_drug[drug]
	    }
	    return total_quantity_available_by_drug
	  end

## DRUGS
	  def art_amount_remaining_if_adherent(from_date,use_visit_date=true,previous_art_date=nil)
	    if use_visit_date
        drug_orders = self.previous_art_drug_orders(from_date)
      else
        drug_orders = self.previous_art_drug_orders(previous_art_date)
      end  
	    days_since_order = from_date - drug_orders.first.date
	    amount_remaining_if_adherent_by_drug = Hash.new(0)

	    consumption_by_drug = Hash.new
	    drug_orders.each{|drug_order|
	      consumption_by_drug[drug_order.drug] = drug_order.daily_consumption
	    }
      
      date = use_visit_date ? from_date : previous_art_date
	    art_quantities_including_amount_remaining_after_previous_visit(date).each{|drug, quantity|
	      amount_remaining_if_adherent_by_drug[drug] = quantity - (days_since_order * consumption_by_drug[drug])
	    }

	    return amount_remaining_if_adherent_by_drug
	  end

	  def num_days_overdue(from_date)
	    self.art_amount_remaining_if_adherent
	  end

	  # Return the earliest date that the patient needs to return to be adherent
## DRUGS
	  def return_dates_by_drug(from_date)
	    drug_orders = self.previous_art_drug_orders(from_date)
	    return nil if drug_orders.nil? or drug_orders.empty?
	    dates_drugs_were_dispensed = drug_orders.first.date
	    date_of_return_by_drug = Hash.new(0)

	    consumption_by_drug = Hash.new
	    drug_orders.each{|drug_order|
	      consumption_by_drug[drug_order.drug] = drug_order.daily_consumption
	    }

	    art_quantities_including_amount_remaining_after_previous_visit(from_date).each{|drug, quantity|
	      days_worth_of_drugs = quantity/consumption_by_drug[drug]
	      date_of_return_by_drug[drug] = dates_drugs_were_dispensed + days_worth_of_drugs 
	    }
	    return date_of_return_by_drug
	  end

	  def date_of_return_if_adherent(from_date)
	    return_dates = return_dates_by_drug(from_date)
	    return_dates.values.sort.first unless return_dates.nil?
	  end

## DRUGS
	  def num_days_overdue_by_drug(from_date)
	    num_days_overdue_by_drug = Hash.new
	    return_dates_by_drug = return_dates_by_drug(from_date)
	    return_dates_by_drug.each{|drug,date|
	      num_days_overdue_by_drug[drug] = (from_date - date).floor
	    } unless return_dates_by_drug.nil?
	    return num_days_overdue_by_drug
	  end

	  def next_appointment_date(from_date = Date.today)

	    
	#
	#   Use the date of perfect adherence to determine when a patient should return (this includes pill count calculations)
	# Give the patient a 2 day buffer
	    adherent_return_date = date_of_return_if_adherent(from_date)
	    return nil if adherent_return_date.nil?

	    recommended_appointment_date = adherent_return_date - 2
	    
	    easter = Patient.date_for_easter(recommended_appointment_date.year)
	    good_friday = easter - 2
	    easter_monday = easter + 1
	    # new years, martyrs, may, freedom, republic, christmas, boxing
	#    holidays = [[1,1],[3,3],[5,1],[6,14],[7,6],[12,25],[12,26], [good_friday.month,good_friday.day]]
	    day_month_when_clinic_closed = GlobalProperty.find_by_property("day_month_when_clinic_closed").property_value + "," + good_friday.day.to_s + "-" + good_friday.month.to_s rescue "1-1,3-3,1-5,14-5,6-7,25-12,26-12"
	    day_month_when_clinic_closed += "," + good_friday.day.to_s + "-" + good_friday.month.to_s    
	    day_month_when_clinic_closed += "," + easter_monday.day.to_s + "-" + easter_monday.month.to_s    
	    recommended_appointment_date += 1 # Ugly hack to initialize properly, we subtract a day in the while loop just below
	    while(true)
	      recommended_appointment_date = recommended_appointment_date - 1

	      if self.child?
		followup_days = GlobalProperty.find_by_property("followup_days_for_children").property_value rescue nil
	      end

	      if followup_days.nil?
		followup_days = GlobalProperty.find_by_property("followup_days").property_value rescue "Monday, Tuesday, Wednesday, Thursday, Friday"
	      end
	      next unless followup_days.split(/, */).include?(Date::DAYNAMES[recommended_appointment_date.wday])

	      ["Saturday","Sunday"].each{|day_to_skip|
		next if Date::DAYNAMES[recommended_appointment_date.wday] == day_to_skip
	      }

	      # String looks like "1-1,25-12"
	      holiday = false
	      day_month_when_clinic_closed.split(/, */).each{|date|
		(day,month)=date.split("-") 
		holiday = true if recommended_appointment_date.month.to_s == month and recommended_appointment_date.day.to_s == day
		break if holiday
	      }
	      next if holiday

	      other_clinic_closed_logic = GlobalProperty.find_by_property("other_clinic_closed_logic").property_value rescue "false"
	  
	      begin
		next if eval other_clinic_closed_logic
	      rescue
	      end

	      break # If we get here then the date is valid
	    end
	    return recommended_appointment_date
	  end

	  def Patient.date_for_easter(year)
	    goldenNumber = year % 19 + 1

	    solarCorrection = (year - 1600) / 100 - (year - 1600) / 400
	    lunarCorrection = (((year - 1400) / 100) * 8) / 25

	    paschalFullMoon = (3 - (11 * goldenNumber) + solarCorrection - lunarCorrection) % 30 
	    --paschalFullMoon if (paschalFullMoon == 29) || (paschalFullMoon == 28 && goldenNumber > 11)

	    dominicalNumber = (year + (year / 4) - (year / 100) + (year / 400)) % 7
	    daysToSunday = (4 - paschalFullMoon - dominicalNumber) % 7 + 1
	    easterOffset = paschalFullMoon + daysToSunday

	    return (Time.local(year, "mar", 21) + (easterOffset * 1.day)).to_date
	  end

	  def Patient.find_by_first_last_sex(first_name, last_name, sex)
	    PatientName.find_all_by_family_name(last_name, :conditions => ["LEFT(given_name,1) = ? AND patient.gender = ? AND patient.voided = false",first_name.first, sex], :joins => "JOIN patient ON patient.patient_id = patient_name.patient_id").collect{|pn|pn.patient}
	  end

	  def Patient.find_by_name(name)
	    # setup a hash to collect all of the patients in. Use a hash indexed by patient id to remove duplicates
	    patient_hash = Hash.new
	# find all patient name objects that have a given_name or family_name like the value passed in
	    # collect thos patient name objects into an array of patient objects
	    PatientName.find(:all,:conditions => ["given_name LIKE ? OR family_name LIKE ?","%#{name}%", "%#{name}%"]).collect{|patient_name| patient_name.patient }.each{ |patient|
	    # add the patient objects to the hash
	      patient_hash[patient.patient_id] = patient
	    }

	    # search for patients with other names matching the value passed int
	    name_type_id = PatientIdentifierType.find_by_name("Other name").patient_identifier_type_id 
	    PatientIdentifier.find(:all, :conditions => ["identifier_type = ? AND identifier LIKE ?",name_type_id,"%#{name}%"]).collect{|patient_identifier| patient_identifier.patient }.each{ |patient|
	    # add the patient objects to the hash
	      patient_hash[patient.patient_id] = patient
	    }
	# return just the values that were stored in the hash (since we used the hash to remove duplicates)
	    return patient_hash.values
	  end
	 
	  def Patient.find_by_birthyear(start_date)
      year = start_date.to_date.year
      Patient.find(:all,:conditions => ["left(birthdate,4) = ?" ,year])
	  end 

	  def Patient.find_by_birthmonth(start_date)
      month = start_date.to_date.month
	    Patient.find(:all,:conditions => ["mid(birthdate,6,2)=?" ,month])
	  end

	  def Patient.find_by_birthday(start_date)
      day = start_date.to_date.day
	    Patient.find(:all,:conditions => ["right(birthdate,2) =?" ,day])
	  end
			
	  
	  def Patient.find_by_residence(residence)
	    PatientAddress.find(:all,:conditions => ["city_village Like ?","%#{residence}%"]).collect{|patient_address| patient_address.patient}
	  end 

	  def  Patient.find_by_birth_place(birthplace)
	   Patient.find(:all,:conditions => ["birthplace Like ?","#{birthplace}%"])
	  end
	  
	  def  Patient.find_by_age(estimate,year)
	    [2,5,10].each{|number|
	      if estimate == "+/- #{number} years"
		      postiveyears = year.to_i +  number
		      negativeyears = year.to_i -  number
		      return Patient.find(:all,:conditions => ["left(birthdate,4) >= ? and left(birthdate,4) <= ?","#{negativeyears}","#{postiveyears}"])
	      end
	    }
	  end

	  def Patient.find_by_national_id(number)
	    national_id_type = PatientIdentifierType.find_by_name("National id").patient_identifier_type_id
	    PatientIdentifier.find(:all,:conditions => ["identifier_type =?  and identifier LIKE ?",national_id_type, "%#{number}%"]).collect{|patient_identifier| patient_identifier.patient}
	  end
	 
	  def Patient.find_by_arv_number(number)
	    arv_national_id_type = PatientIdentifierType.find_by_name("ARV national id").patient_identifier_type_id
	    PatientIdentifier.find(:all,:conditions => ["identifier_type =?  and identifier LIKE ?",arv_national_id_type, "% #{number}%"]).collect{|patient_identifier| patient_identifier.patient}
	  end
	 
	  attr_accessor :reason
	  
	  def occupation
	    identifier_type_id = PatientIdentifierType.find_by_name("Occupation").patient_identifier_type_id
	    value = PatientIdentifier.find_by_patient_id_and_identifier_type(self.id, identifier_type_id, :conditions => "voided = 0")
	    value.identifier if value
	  end 
	  
	  def occupation=(value)
	    identifier_type_id = PatientIdentifierType.find_by_name("Occupation").patient_identifier_type_id
	    current_occupation = PatientIdentifier.find_by_patient_id_and_identifier_type(self.id, identifier_type_id, :conditions => "voided = 0")
	    return if current_occupation and current_occupation.identifier == value
	    # TODO BUG: reason is not set
	    current_occupation.void! reason unless current_occupation.nil?
	    PatientIdentifier.create!(:identifier => value, :identifier_type => identifier_type_id, :patient_id => self.id)
	  end
	  
	  def patient_location_landmark
	    identifier_type_id= PatientIdentifierType.find_by_name("Physical address").patient_identifier_type_id
	    value = PatientIdentifier.find_by_patient_id_and_identifier_type(self.id,identifier_type_id, :conditions => "voided = 0")
	    return value.identifier if value
	  end
	  
	  def patient_location_landmark=(value)
	    identifier_type_id= PatientIdentifierType.find_by_name("Physical address").id
	    curr_value = PatientIdentifier.find_by_patient_id_and_identifier_type(self.id,identifier_type_id, :conditions => "voided = 0")
	    return if curr_value and curr_value.identifier == value
	    curr_value.void! reason if curr_value
	    PatientIdentifier.create!(:identifier => value, :identifier_type => identifier_type_id, :patient_id => self.id)
	  end
	  
	  def physical_address
	    return PatientAddress.find_by_patient_id(self.id, :conditions => "voided = 0").city_village unless  PatientAddress.find_by_patient_id(self.id).nil?
	  end
	     
	  def Patient.find_by_patient_name(first_name,last_name)
	      first_name=first_name.strip[0..0]
	      patient_hash = Hash.new
	# find all patient name objects that have a given_name or family_name like the value passed in
	      # collect thos patient name objects into an array of patient objects
	      PatientName.find(:all,:conditions => ["given_name LIKE ? and family_name LIKE ?","#{first_name}%", "#{last_name}%"]).collect{|patient_name| patient_name.patient }.each{ |patient|
		# add the patient objects to the array
	       patient_hash[patient.patient_id] = patient
	    }
	    return patient_hash.values
	  end

	  def Patient.find_by_patient_names(first_name,other_name,last_name)
	      first_name=first_name.strip[0..0]
	      other_name=other_name.strip[0..0]
	      patient_hash = Hash.new
	# find all patient name objects that have a given_name or family_name like the value passed in
	      # collect thos patient name objects into an array of patient objects
	      PatientName.find(:all,:conditions => ["given_name LIKE ? and family_name LIKE ?","#{first_name}%", "#{last_name}%"]).collect{|patient_name| patient_name.patient }.each{ |patient|
	     # add the patient objects to the array
	      patient_hash[patient.patient_id] = patient
	    }

	     # search for patients with other names matching the value passed int
	      name_type_id = PatientIdentifierType.find_by_name("Other name").patient_identifier_type_id
	      PatientIdentifier.find(:all, :conditions => ["identifier_type = ? AND identifier LIKE ?",name_type_id,"#{other_name}%"]).collect{|patient_identifier| patient_identifier.patient }.each{ |patient|
	      # add the patient objects to the hash
	      patient_hash[patient.patient_id] = patient
	    }
	    
	    return patient_hash.values
	  end 
	  
	   def Patient.find_by_patient_surname(last_name)
	      patient_hash = Hash.new
	      # collect thos patient name objects into an array of patient objects
	      PatientName.find(:all,:conditions => ["family_name LIKE ?","#{last_name}%"]).collect{|patient_name| patient_name.patient }.each{ |patient|
	       # add the patient objects to the array
	       patient_hash[patient.patient_id] = patient
	    }
	       return patient_hash.values
	   end

	  def validate 
	    errors.add(:birthdate, "cannot be in the future") if  self.birthdate > Date.today unless self.birthdate.nil?
	  end

=begin 
This seems incompleted, replaced with new method at top
	  def Patient.merge(patient1,patient2)
	    merged_patient = Patient.new
	    merged_patient.fields #TODO
	    merged_patient.birthdate #TODO
	    merged_patient.birthdate_estimated
	    merged_patient_name = PatientName.new
	    merged_patient_name.patient = merged_patient
	    merged_patient.patient_name #TODO
	    merged_patient_address = PatientAddress.new
	    merged_patient_address = TODO
	    merged_patient_ta = PatientIdentifier.new
	    merged_patient_other_name = PatientIdentifier.new
	    merged_patient_cell = PatientIdentifier.new
	    merged_patient_office = PatientIdentifier.new
	    merged_patient_home = PatientIdentifier.new
	    merged_patient_occupation = PatientIdentifier.new
	    merged_patient_physical_address = PatientIdentifier.new
	    merged_patient_national_id = PatientIdentifier.new
	    merged_patient_art_guardian #TODO
	    merged_patient_filing_number = PatientIdentifier.new
	    merged_patient_encounters #TODO
	    merged_patient_observations #TODO
	  end
=end

	  def Patient.total_number_of_patients_registered
	    return Patient.find(:all).collect{|pat|
	       if(! pat.filing_number.nil?)
	       pat.filing_number
	     end
	   }.compact.length
	  end
	  


	  def  Patient.today_number_of_patients_with_their_vitals_taken
	    enc_type=EncounterType.find_by_name("Height/Weight").id
	    return Patient.find(:all).collect{|pat|
	    if( ! pat.encounters.find_by_type_name("Height/Weight").empty? )
	      count= Encounter.count_by_sql "SELECT count(*) FROM openmrs.encounter where patient_id=#{pat.patient_id} and encounter_type=#{enc_type}  and str_to_date(encounter_datetime,'%Y-%m-%d') = '#{Date.today.strftime("%Y-%m-%d")}'"
		if count > 0 then
		pat.patient_id
	       end
	    end
	    }.compact.length
	  end
	  def Patient.return_visits(patient_type,start_date,end_date)
	     start_date =start_date.to_date.strftime("%Y-%m-%d")
	     end_date = end_date.to_date.strftime("%Y-%m-%d")
	     
	     case patient_type
	       when "Female","Male"
		 patients=  Patient.find(:all,:conditions => ["(datediff(Now(),birthdate))> (365*15) and gender=?",patient_type])
	       when "Under 15 years"
		 patients= Patient.find(:all,:conditions => ["(datediff(Now(),birthdate)) <  (365*15)"])
	       when "All Patients"
		 patients= Patient.find(:all)
	     end
	    
	     return patients.collect{|pat|
	       next if ! pat.art_patient?
	       pat_obs=Observation.find(:first,:include=>'patient',:conditions => ["obs.obs_datetime >= ? and obs.obs_datetime <= ? and obs.patient_id=?",start_date,end_date,pat.patient_id],:order=>"obs.obs_datetime" ,:order=>"obs.obs_datetime desc")
	       if pat.date_created.strftime("%Y-%m-%d") < start_date.to_date.strftime("%Y-%m-%d")  and ! pat_obs.nil?
		 report = Hash.new
		 report["date_visited"] =pat_obs.obs_datetime 
		 report["patient_id"] = pat.national_id
		 report["filing_number"] = pat.filing_number
	       end
	       report
	     }.flatten.compact

	     return report
	  
	  end
	   
	   def Patient.find_patients_adults(patient_type,start_date,end_date)
	       
	     case patient_type
	       when "Female","Male"
		 patients=  Patient.find(:all,:conditions => ["(datediff(Now(),birthdate))> (365*15) and gender=?",patient_type])
	       when "Under 15 years"
		 patients= Patient.find(:all,:conditions => ["(datediff(Now(),birthdate)) <  (365*15)"])
	       when "All Patients"
		 patients= Patient.find(:all)
	     end
	     
	     return patients.collect{|pat|
	       if pat.date_created.strftime("%Y,%m,%d") >= start_date.to_date.strftime("%Y,%m,%d") and  pat.date_created.strftime("%Y,%m,%d")<= end_date.to_date.strftime("%Y,%m,%d") and pat.art_patient?
		 pat
	       end
	     }.compact
	   end
	  
	  
	   def Patient.find_today_number_of_initial_visits
	   return Patient.find(:all, :conditions => ["DATE(patient.date_created) = ?",Date.today] ).collect{|pat|
	   if ! pat.filing_number.nil?
		pat.filing_number
	    end
	    }.compact.length
	   
	   end
			  
	   def Patient.find_today_number_of_follow_up_visits
	     todays_total_visits=Patient.find_todays_total_visits 
	     today_number_of_initial_visits= Patient.find_today_number_of_initial_visits
	     return todays_total_visits.to_i - today_number_of_initial_visits.to_i if todays_total_visits.to_i > today_number_of_initial_visits.to_i
	     return 0
	   end

	   def  Patient.find_todays_total_visits
	     enc_type=(EncounterType.find_by_name("HIV Reception").id)
	     return Encounter.art_total_number_of_patients_visit(Date.today,enc_type).length
	   end

	   def  Patient.find_total_number_of_patients_visited_today
	      return Encounter.count_total_number(Date.today) 
	      #return (Patient.find_today_number_of_follow_up_visits) + (Patient.find_today_number_of_initial_visits)
	   end
	   

	   def  Patient.intial_visits(date,patient_type)
	     
	     case patient_type
	       when "Male" , "Female"
		 patients= Patient.find(:all, :conditions => ["DATE(patient.date_created) = ? and patient.gender= ?",date,patient_type])
	       when "Under 15 years"
		 patients= Patient.find(:all,:conditions => ["datediff(Now(),birthdate)) <  (365*15) and DATE(patient.date_created) = ?",date])
	       when "All Patients"
		 patients= Patient.find(:all, :conditions => ["DATE(patient.date_created) = ?",date])
	     end  
	     
	     return patients.collect{|pat|
		 unless pat.filing_number.nil?
		   pat
		 end
	     }.compact
		
	   end

	   def  Patient.total_visits(date,patient_type)
	     
	     case patient_type
	       when "Male" , "Female"
		 patients=  Patient.find(:all, :conditions => ["datediff(Now(),birthdate) >  (365*15) and DATE(patient.date_created) <= ? and patient.gender= ?",date,patient_type])
	       when "Under 15 years"
		 patients= Patient.find(:all,:conditions => ["datediff(Now(),birthdate) <  (365*15) and DATE(patient.date_created) <= ?",date])
	       when "All Patients"
		 patients= Patient.find(:all, :conditions => ["DATE(patient.date_created) <= ?",date])
	     end  

	     return patients.collect{|pat|
		unless pat.filing_number.nil?
		 pat
		end
	     }.compact
	    
	   end
	   
	   def Patient.vitals_in_detail(date,patient_type)
	     
	     date=date.to_date.strftime("%Y-%m-%d") 
	     case patient_type
	       when "Male" , "Female"
		 patients=  Patient.find_all_by_gender(patient_type)
	       when "Under 15 years"
		 patients= Patient.find(:all,:conditions => ["(datediff(Now(),birthdate)) <  (365*15)"])
	       when "All Patients"
		 patients= Patient.find(:all)
	     end  
	     
	     return if patients.nil? 
	     enc_type=EncounterType.find_by_name("Height/Weight").id
	     patients.collect{|pat|
	     if( ! pat.encounters.find_by_type_name("Height/Weight").empty? )
		 count= Encounter.count_by_sql "SELECT count(*) FROM openmrs.encounter where patient_id=#{pat.patient_id} and encounter_type=#{enc_type}  and Date(encounter_datetime) = '#{date}'"
		   if count > 0 then
		     pat
		   end
	     end
	    }.compact

	    patent_results=Hash.new 
	    patients.each{|pat|
	    pat_information=Observation.find(:all, :include => "patient", :conditions => ["DATE(obs.date_created) = ? and obs.patient_id=?",date,pat.patient_id]).collect{|o|o.result_to_string}
	      if pat_information[0].to_f != 0.0 and pat_information[1].to_f !=0.0 
		patent_results[pat.patient_id]=pat_information[0],pat_information[1]
	      elsif  pat_information[0].to_f != 0.0 and pat_information[1].to_f == 0.0
		  patent_results[pat.patient_id]=pat_information[0],pat.observations.find_last_by_concept_name("Height").value_numeric
	      elsif  pat_information[0].to_f == 0.0 and pat_information[1].to_f != 0.0
		  patent_results[pat.patient_id]=pat.observations.find_last_by_concept_name("Weight").value_numeric, pat_information[0]
	      end 
	     }   
	    return patent_results  
	   end
	  
	  def Patient.patient_type(date,patient_type)
	    #to make sure we dont select peads(children) too,we do a datediff inorder to select patients over 15 years. There are 5475 days in 15 years hence: (365*15) in the query!
	      case patient_type
		when "Male" , "Female"
		  return Observation.find(:all,:include=>'patient',:conditions => ["(datediff(Now(),birthdate)) >  (365*15) and Date(obs.obs_datetime)<= ? and patient.gender=?", date,patient_type], :order => "obs_datetime desc")
		when "Under 15 years"
		  return Observation.find(:all,:include=>'patient',:conditions => ["(datediff(Now(),birthdate)) <  (365*15) and Date(obs.obs_datetime)<= ?", date], :order => "obs_datetime desc")
		when "All Patients"
		  return Observation.find(:all,:include=>'patient',:conditions => ["Date(obs.obs_datetime)<= ?",date], :order => "obs_datetime desc")
	      end  
	  end
	  
	  def Patient.virtual_register
	    #art_location_name = Patient.art_clinic_name(location_id)
	    art_location_name = Location.health_center.name
	    patient_register=Hash.new
		Observation.find(:all,:group=>"obs.patient_id",:order => "obs_datetime desc").collect{|obs|
		  
		  hash_key=obs.obs_datetime.strftime("%Y%m%d").to_s + obs.patient_id.to_s
		  pat=Patient.find(obs.patient_id) rescue nil
		  next if pat.nil?
		  if_patient_has_arv_number=pat.ARV_national_id
		  next if if_patient_has_arv_number.nil? # this code makes sure that,only patients with arv_numbers are shown
		  patient_register[hash_key]= ArtRegisterEntry.new()
		  date_started_arts=pat.date_started_art
		  patient_register[hash_key].date_of_registration=date_started_arts.strftime("%d %b %Y") unless date_started_arts.nil?
		  patient_register[hash_key].quarter=(date_started_arts.month.to_f/3).ceil unless date_started_arts.nil?
		  patient_register[hash_key].name = pat.name
		  patient_register[hash_key].sex = pat.gender  == "Male" ? "M" : "F"
		  patient_register[hash_key].age=pat.age
		  patient_address = pat.physical_address
		  patient_land_mark = pat.get_identifier("Physical address")
		  patient_register[hash_key].address=patient_address.to_s + " /  " + patient_land_mark.to_s unless patient_land_mark.blank? and patient_address.blank?
		  patient_register[hash_key].address=patient_address.to_s if !patient_land_mark.blank? and patient_address.blank?
		  occupation=pat.occupation
		  patient_register[hash_key].occupation= "Not Available"
		  patient_register[hash_key].occupation=occupation unless occupation.nil?
		  patient_register[hash_key].date_of_visit=pat.patient_visit_date #obs.obs_datetime.strftime("%d-%b-%Y")
		  reason =  pat.reason_for_art_eligibility
		  unless reason.nil?
		    reason_for_starting = reason.name
		    reason_for_starting.gsub!(/WHO|adult|child|count/i,"")
		    reason_for_starting.gsub!(/stage/i,"Stage")
		    patient_register[hash_key].reason_for_starting_arv = reason_for_starting
		  end
		  art_guardian=pat.art_guardian
		  patient_register[hash_key].guardian=art_guardian.name.to_s unless art_guardian.nil?
		  patient_register[hash_key].guardian="No guardian" if  patient_register[hash_key].guardian.nil?
		  patient_register[hash_key].art_treatment_unit = art_location_name
		  patient_register[hash_key].arv_registration_number = pat.ARV_national_id ? pat.ARV_national_id : "MPC number unavailable" 
		  patient_register[hash_key].ptb=pat.requested_observation("PTB within the past 2 years")
		  patient_register[hash_key].eptb=pat.requested_observation("Extrapulmonary tuberculosis (EPTB)")
		  patient_register[hash_key].kaposissarcoma=pat.requested_observation("Kaposi's sarcoma")
		  patient_register[hash_key].refered_by_pmtct=pat.requested_observation("Referred by PMTCT")

		  outcome_date=""
		  
		  ["Continue treatment at current clinic","Outcome","Date of first positive HIV test","Is at work/school","Date of ART initiation","Is able to walk unaided","ARV regimen","Weight","Peripheral neuropathy","Hepatitis","Skin rash","Lactic acidosis","Lipodystrophy","Anaemia","Whole tablets remaining and brought to clinic"].each{|concept_name|
		  patient_observations = Observation.find(:all,:conditions => ["concept_id=? and patient_id=?",(Concept.find_by_name(concept_name).id),pat.patient_id],:order=>"obs.obs_datetime desc").compact
		    case concept_name
		    when "Continue treatment at current clinic" 
		      unless  patient_observations.first.nil?
			outcome=Concept.find_by_concept_id(patient_observations.first.value_coded).name
			outcome="Alive and on ART" if outcome=="Yes"
			patient_register[hash_key].outcome_status=outcome
			patient_register[hash_key].outcome_status.gsub!(/On ART.*/,"On ART")
			outcome_date= patient_observations.first.obs_datetime
			outcome_date=outcome_date.strftime("%Y %b %d")
		      else
			patient_register[hash_key].outcome_status="On ART"
		      end  
		    when "Outcome" 
		      unless   patient_observations.first.nil?
		       if outcome_date.nil? or (!outcome_date.nil? and  patient_observations.first.obs_datetime.strftime("%Y %b %d")>=outcome_date)
			 patient_register[hash_key].outcome_status=Concept.find_by_concept_id(patient_observations.first.value_coded).name

			 patient_register[hash_key].outcome_status.gsub!(/Transfer Out.*/,"Transfer out")
		       end     
		      end  
		    when "Date of first positive HIV test"
		      unless  patient_observations.first.nil?
			patient_register[hash_key].date_first_started_arv_drugs=patient_observations.first.value_datetime.to_date.strftime("%d %b %Y") if patient_observations.first && patient_observations.first.value_datetime
			patient_register[hash_key].date_first_started_arv_drugs ||= Date.new(0,1,1)
		      else
			patient_register[hash_key].date_first_started_arv_drugs="Unavailable"
		      end 
		    when "Is at work/school"
		      unless   patient_observations.first.nil?
			patient_register[hash_key].at_work_or_school=Concept.find_by_concept_id(patient_observations.first.value_coded).name
		      else
			patient_register[hash_key].at_work_or_school="Unavailable"
		      end 
		    when "Date of ART initiation"
		      unless  patient_observations.first.nil?
			patient_register[hash_key].date_of_art_initiation=patient_observations.first.result_to_string.to_date.strftime("%d %b %Y")
		      else
			date_started=pat.date_started_art
			patient_register[hash_key].date_of_art_initiation= date_started.nil? ?  "Unavailable" : date_started.strftime("%d %b %Y")
		      end 
		    when "Is able to walk unaided"
		      unless  patient_observations.first.nil?
			patient_register[hash_key].ambulant=Concept.find_by_concept_id(patient_observations.first.value_coded).name
		      else
			patient_register[hash_key].ambulant="Unavailable"
		      end 
	#data elements pulled at the request of queens
	#the register uses a class ArtRegisterEntry to define the various objects of the class
	#added objects are: weight and side effects
		    when "Weight"
		      unless  patient_observations.nil?
			  patient_register[hash_key].last_weight = patient_observations.last.blank? || patient_observations.last.value_numeric.nil? ? "Unavailable" :  patient_observations.last.value_numeric
			  patient_register[hash_key].first_weight = patient_observations.first.blank? ||patient_observations.first.value_numeric.nil? ? "Unavailable" :  patient_observations.first.value_numeric
		      end 
		    when "Peripheral neuropathy"
		      unless  patient_observations.first.nil?
			patient_register[hash_key].peripheral_neuropathy = Concept.find_by_concept_id(patient_observations.first.value_coded).name
		      else
			patient_register[hash_key].peripheral_neuropathy = "Unavailable"
		      end 
		     when "Hepatitis"
		      unless  patient_observations.first.nil?
			patient_register[hash_key].hepatitis=Concept.find_by_concept_id(patient_observations.first.value_coded).name
		      else
			patient_register[hash_key].hepatitis="Unavailable"
		      end 
		     when "Skin rash"
		      unless  patient_observations.first.nil?
			patient_register[hash_key].skin_rash=Concept.find_by_concept_id(patient_observations.first.value_coded).name
		      else
			patient_register[hash_key].skin_rash="Unavailable"
		      end 
		     when "Lactic acidosis"
		      unless  patient_observations.first.nil?
			patient_register[hash_key].lactic_acidosis = Concept.find_by_concept_id(patient_observations.first.value_coded).name
		      else
			patient_register[hash_key].lactic_acidosis = "Unavailable"
		      end 
		     when "Lipodystrophy"
		      unless  patient_observations.first.nil?
			patient_register[hash_key].lipodystrophy=Concept.find_by_concept_id(patient_observations.first.value_coded).name
		      else
			patient_register[hash_key].lipodystrophy="Unavailable"
		      end 
		     when "Anaemia"
		      unless  patient_observations.first.nil?
			patient_register[hash_key].anaemia=Concept.find_by_concept_id(patient_observations.first.value_coded).name
		      else
			patient_register[hash_key].anaemia="Unavailable"
		      end 
		     when "Other side effect"
		      unless  patient_observations.first.nil?
			patient_register[hash_key].other=Concept.find_by_concept_id(patient_observations.first.value_coded).name
		      else
			patient_register[hash_key].other="Unavailable"
		      end 
		    when "ARV regimen"
		      unless  patient_observations.first.nil?
			patient_register[hash_key].arv_regimen=Concept.find_by_concept_id(patient_observations.first.value_coded).short_name
		      else
			patient_register[hash_key].arv_regimen="Not available"
		      end 
		     when "Whole tablets remaining and brought to clinic"
		      unless  patient_observations.first.nil?
			patient_register[hash_key].tablets_remaining=patient_observations.first.value_numeric
		      else
			patient_register[hash_key].tablets_remaining="Not available"
		      end  
		    end 
		   


		  }
	      }
	    patient_register 
	  end
	  
	  def Patient.art_clinic_name(location_id)
	    location_id= Location.find_by_location_id(location_id).parent_location_id
	    Location.find_by_location_id(location_id).name
	  end

	  def requested_observation(name)
	    requested_observation = self.observations.find_last_by_concept_name(name)
	    return requested_observation="-" if requested_observation.nil?
	    requested_observation=requested_observation.result_to_string
	    return requested_observation
	  end
	  
	  def requested_observation_by_name_date(name,date)
	    requested_observation = self.observations.find_last_by_concept_name_on_date(name,date)
	    return requested_observation="-" if requested_observation.nil?
	    requested_observation=requested_observation.result_to_string
	    return requested_observation
	  end
	  
	  def set_last_height(height, date)
	    observation = Observation.new
	    observation.patient = self
	    observation.concept = Concept.find_by_name("Height")
	    observation.value_numeric = height
	    observation.obs_datetime = date
	    observation.save
	  end
	  
	  def set_last_weight(weight, date)
	    weight = weight.to_f
	    observation = Observation.new
	    observation.patient = self
	    observation.concept = Concept.find_by_name("Weight")
	    observation.value_numeric = weight
	    observation.obs_datetime = date
	    observation.save
	  end
	  
	  def set_art_visit_reg(enc_name,value,date)
	    return if value.nil?
	    encounter_name = self.encounters.find_first_by_type_name("ART Visit")
	    if encounter_name.nil?
	      encounter_name = Encounter.new
	      encounter_name.patient = self
	      encounter_name.type = EncounterType.find_by_name("ART Visit")
	      encounter_name.encounter_datetime = date
	      encounter_name.save
	    end

	    obs = Observation.new
	    obs.encounter = encounter_name
	    obs.patient = self
	    obs.concept = Concept.find_by_name(enc_name)
	    obs.value_coded = Drug.find_by_name(value).id
	    obs.obs_datetime = date
	    obs.save
	  end
	  
	  def set_art_visit_encounter(enc_name,value,date)
	    return if value.nil? || enc_name.nil? || date.nil?
	    encounter = self.encounters.find_first_by_type_name("ART Visit")
	    if encounter.blank?
	      encounter = Encounter.new
	      encounter.patient = self
	      encounter.type = EncounterType.find_by_name("ART Visit")
	      encounter.encounter_datetime = date
	      encounter.provider_id = User.current_user.id
	      encounter.save
	    end

	    obs = Observation.new
	    obs.encounter = encounter
	    obs.patient = self
	    obs.concept = Concept.find_by_name(enc_name)
	    obs.value_coded = Concept.find_by_name(value).id
	    obs.obs_datetime = date
	    obs.save
	  end
	  
	  def set_outcome(outcome,date)
	  return if outcome.nil? || date.nil?
	    encounter = self.encounters.find_first_by_type_name("Update outcome")
	    if encounter.blank?
	      encounter = Encounter.new
	      encounter.patient = self
	      encounter.type = EncounterType.find_by_name("Update outcome")
	      encounter.encounter_datetime = date
	      encounter.provider_id = User.current_user.id
	      encounter.save
	    end

	    obs = Observation.new
	    obs.encounter = encounter
	    obs.patient = self
	    obs.concept = Concept.find_by_name("Outcome")
	    obs.value_coded = Concept.find_by_name(outcome).id
	    obs.obs_datetime = date
	    obs.save
	    if outcome == "Died"
	      self.death_date = date
	      self.save
	    end  
	  end 
    
## DRUGS
	  def set_last_arv_reg(drug_name,prescribe_amount,date)
	    return if drug_name.nil?
	    encounter = self.encounters.find_by_type_name_and_date("Give drugs",date)
	    if encounter.blank?
	      encounter = Encounter.new
	      encounter.patient = self
	      encounter.type = EncounterType.find_by_name("Give drugs")
	      encounter.encounter_datetime = date
	      encounter.provider_id = User.current_user 
	      encounter.save
	    else
	      encounter = encounter.first 
	    end
	    
	    order=Order.new
	    order.order_type_id = OrderType.find_by_name("Give drugs").id
	    order.encounter_id = encounter.id
	    order.date_created = date
	    order.orderer = User.current_user
	    order.save

	    drug_order = DrugOrder.new
	    drug_order.order_id = order.id
	    drug_order.quantity=prescribe_amount
	    drug_order.drug_inventory_id=Drug.find_by_name(drug_name).id
	    drug_order.save
	  end
	  
## DRUGS
	  def set_art_visit_pill_count(drug_name,number_counted,date)
	    return if drug_name.nil?
	    encounter = self.encounters.find_first_by_type_name("ART Visit")
	    if encounter.blank?
	      encounter = Encounter.new
	      encounter.patient = self
	      encounter.type = EncounterType.find_by_name("ART Visit")
	      encounter.encounter_datetime = date
	      encounter.provider_id = User.current_user
	      encounter.save
	    end

	    obs = Observation.new
	    obs.encounter = encounter
	    obs.patient = self
	    obs.concept = Concept.find_by_name("Whole tablets remaining and brought to clinic")
	    obs.value_numeric = number_counted
	    obs.value_drug = Drug.find_by_name(drug_name).id
	    obs.obs_datetime = date
	    obs.save
	  end
	  
	  def set_type_of_visit(visit_by,date) 
	    encounter = self.encounters.find_first_by_type_name("HIV Reception")
	    if encounter.blank?
	      encounter = Encounter.new
	      encounter.patient = self
	      encounter.type = EncounterType.find_by_name("HIV Reception")
	      encounter.provider_id = User.current_user
	      encounter.encounter_datetime = date
	      encounter.save
	    
	      obs = Observation.new
	      obs.encounter = encounter
	      obs.patient = self
	      obs.concept = Concept.find_by_name(visit_by)
	      obs.obs_datetime = date
	      obs.save
	    end
	  end

	  def place_of_first_hiv_test 
	    location=self.observations.find_first_by_concept_name("Location of first positive HIV test")
	    location_id=location.value_numeric unless location.nil?
	    return nil if location_id.nil?
	    name = Location.find(location_id).name rescue nil # unless location_id.nil?
	    return name  
	  end

	  def set_hiv_test_location(location_name,date)
	    return if location_name.nil?
	    date = Time.now if date.blank?
	    encounter_name = self.encounters.find_first_by_type_name("HIV Staging")
	    if encounter_name.nil?
	      encounter_name = Encounter.new
	      encounter_name.patient = self
	      encounter_name.type = EncounterType.find_by_name("HIV Staging")
	      encounter_name.encounter_datetime = date
	      encounter_name.provider_id = User.current_user.id
	      encounter_name.save
	    end

	    obs = Observation.new
	    obs.encounter = encounter_name
	    obs.patient = self
	    obs.concept = Concept.find_by_name("Location of first positive HIV test")
	    lacation_id=Location.find_by_name(location_name).id
	    location_id = Location.find_by_sql("select location_id from location where name like \"%#{location_name}%\"")[0].location_id if location_id.nil?
	    obs.value_numeric=location_id
	    obs.obs_datetime = date
	    obs.save
	  end
	  
	  def set_art_staging_encounter(concept_name,value,date)
	    return if concept_name.nil? || concept_name.empty?
	    encounter_name = self.encounters.find_first_by_type_name("HIV Staging")
	    if encounter_name.blank?
	      encounter_name = Encounter.new
	      encounter_name.patient = self
	      encounter_name.type = EncounterType.find_by_name("HIV Staging")
	      encounter_name.encounter_datetime = date
	      encounter_name.provider_id = User.current_user.id
	      encounter_name.save
	    end

	    obs = Observation.new
	    obs.encounter = encounter_name
	    obs.patient = self
	#    puts concept_name + "..............patient model"
	    obs.concept_id = Concept.find_by_name(concept_name).id
	    obs.value_coded = Concept.find_by_name(value).id
	    obs.obs_datetime = date
	    obs.save
	  end
	  
	  def set_art_staging_int_cd4(cd4_count,cd4_modifier,date)
	    return if cd4_count.nil?
	    encounter_name = self.encounters.find_first_by_type_name("HIV Staging")
	    if encounter_name.blank?
	      encounter_name = Encounter.new
	      encounter_name.provider_id = User.current_user 
	      encounter_name.patient = self
	      encounter_name.type = EncounterType.find_by_name("HIV Staging")
	      encounter_name.encounter_datetime = date
	      encounter_name.save
	    end

	    obs = Observation.new
	    obs.encounter = encounter_name
	    obs.patient = self
	    obs.concept = Concept.find_by_name("CD4 Count")
	    obs.value_numeric = cd4_count
	    obs.value_modifier = cd4_modifier
	    obs.obs_datetime = date
	    obs.save
	  end
	  
	  def last_cd4_count
	   obs = Observation.find(:all,:conditions => ["concept_id=? and patient_id=?",(Concept.find_by_name("CD4 Count").id),self.patient_id],:order=>"obs.obs_datetime desc").first
	   return nil if obs.nil?
	   value_modifier = obs.value_modifier 
	   cd4_count= obs.value_numeric
	   return cd4_count
	  end
	   
	  def set_art_receiver(value,date) 
	    return if value.nil?
	    encounter_name = self.encounters.find_by_type_name_and_date("HIV Reception",date).first
	    if encounter_name.blank?
	      encounter_name = Encounter.new
	      encounter_name.patient = self
	      encounter_name.type = EncounterType.find_by_name("HIV Reception")
	      encounter_name.encounter_datetime = date
	      encounter_name.save
	    end

	    obs = Observation.new
	    obs.encounter = encounter_name
	    obs.patient = self
	    obs.concept = Concept.find_by_name(value)
	    obs.value_coded = Concept.find_by_name(value).id
	    obs.obs_datetime = date
	    obs.save
	  end
	  
	  def guardian_present?(date=Date.today)
	      encounter = self.encounters.find_by_type_name_and_date("HIV Reception", date).last
	      guardian_present=encounter.observations.find_last_by_concept_name("Guardian present").to_s unless encounter.nil?

	      return false if guardian_present.blank?
	      return false if guardian_present.match(/No/)
	      return true
	  end
	  
	  def patient_present?(date=Date.today)
	      encounter = self.encounters.find_by_type_name_and_date("HIV Reception", date).last
	      patient_present=encounter.observations.find_last_by_concept_name("Patient present").to_s unless encounter.nil?

	      return false if patient_present.blank?
	      return false if patient_present.match(/No/)
	      return true
	  end
	  
	  def patient_and_guardian_present?(date=Date.today)
	      patient_present = self.patient_present?(date)
	      guardian_present = self.guardian_present?(date)

	      return false if !patient_present || !guardian_present
	      return true
	  end
	   
	  def update_pmtct
	    pat_nat_id = FasterCSV.read("/home/bond/Desktop/PatID_pmtct2.csv")
	    pat_id = pat_nat_id.collect{|pat|Patient.find_by_national_id(pat)}
	    pmtct_obs = pat_id.collect{|pat|pat.observations.find_by_concept_name("Referred by PMTCT").collect{|obs|obs.value_coded = "3"}}
	    pmtct_obs.save!
	  end 
	  
	  def patient_visit_date
	    enc_type_id =EncounterType.find_by_name("Height/Weight").id
	    enc_type = Encounter.find(:all,:conditions=>["patient_id=? and encounter_type=?",self.patient_id,enc_type_id],:order=>"encounter_datetime DESC")
	    unless enc_type.blank?
	      return enc_type.first.encounter_datetime.strftime("%d %b %Y")
	    else
	      return nil
	    end
	  end 

		def get_cohort_visit_data(start_date=nil, end_date=nil)
			start_date = Encounter.find(:first, :order => "encounter_datetime").encounter_datetime.to_date if start_date.nil?
			end_date = Date.today if end_date.nil?

			last_year_in_quarter = end_date.year
			if end_date.month != end_date.next.month
				last_month_in_quarter = end_date.month
			else
				last_month_in_quarter = end_date.month - 1
				if last_month_in_quarter == 0
					last_month_in_quarter = 12
					last_year_in_quarter -= 1
				end
			end
		
      # in Reports::CohortByRegistration, we now only need Staging data from this method
			patient_encounters = Encounter.find(:all, 
        :conditions => ["encounter.patient_id = ? AND encounter.encounter_type = ? AND 
                         DATE(encounter_datetime) >= ? AND DATE(encounter_datetime) <= ?", 
                         self.id, EncounterType.find_by_name('HIV Staging').id,start_date, end_date], 
        :order => "encounter_datetime DESC")
			cohort_visit_data = Hash.new
			followup_done = true #false
			staging_done = false
			pill_count_done = true #false

			total_encounters = patient_encounters.length
			i = 0
			while i < total_encounters
				this_encounter = patient_encounters[i]
				cohort_visit_data["last_encounter_datetime"] = this_encounter.encounter_datetime if i == 0
				cohort_visit_data["Last month"] = last_month_in_quarter
        this_encounter_observations = this_encounter.observations
=begin
        if this_encounter.name == "ART Visit" and not followup_done
					this_encounter_observations.each { |o|
						this_concept = o.concept.name
            result = o.result_to_string
						cohort_visit_data[this_concept] = !result.blank? && result.include?('Yes')  # Cohort side effects should only count 'Yes drug induced'
					}
					followup_done = true

					#break
				end
				if this_encounter.name == "ART Visit" and not pill_count_done
					this_encounter_observations.each { |o|
						this_concept = o.concept.name
						if this_concept == "Whole tablets remaining and brought to clinic" or 
							 this_concept == "Whole tablets remaining but not brought to clinic" 

							unless o.value_numeric.nil? or (o.obs_datetime.to_date.month != last_month_in_quarter or 
																							o.obs_datetime.to_date.year != last_year_in_quarter)
								if cohort_visit_data["Pill count"].nil?
									cohort_visit_data["Pill count"] = o.value_numeric
								else
									cohort_visit_data["Pill count"] += o.value_numeric
								end

								cohort_visit_data["Last month"] = last_month_in_quarter
								pill_count_done = true
							end

						end
					}
        end
=end
				if this_encounter.name == "HIV Staging" and not staging_done
					this_encounter_observations.each{ |o| 
						this_concept = o.concept.name
						if this_concept == "CD4 count"
							cohort_visit_data[this_concept] = o.value_numeric
						elsif this_concept == "CD4 test date"
							cohort_visit_data[this_concept] = o.obs_datetime
						else
							cohort_visit_data[this_concept] = o.value_coded == 3 # 3 is the concept_id for 'Yes'
						end
					}
					staging_done = true
				end

				break if followup_done and staging_done and pill_count_done
				i += 1
			end
			return cohort_visit_data
		end 
		
		def is_dead?
			self.outcome_status == "Died"
		end  
	  
	  def last_visit_date(date)
	    number_of_months =(Date.today - date).to_i
	    number_of_months/30
	  end  

	  def remove_first_relationship(relationship_name) 
	    guardian_type = RelationshipType.find_by_name("ART Guardian")
	    person = self.people[0]
	    rel = Relationship.find(:first, :conditions => ["voided = 0 AND relationship = ? AND person_id = ?", guardian_type.id, person.id], :order => "date_created DESC") unless person.nil?
	   if rel
	    rel.void! "Modifying Mastercard" 
	    self.reload
	   end 
	  end

	  def national_id_label(num = 1)
	    self.set_national_id unless self.national_id
	    birth_date = self.birthdate_for_printing
	    sex =  self.gender == "Female" ? "(F)" : "(M)"
	    national_id_and_birthdate=self.print_national_id  + " " + birth_date
	    address = self.person_address
	    address = address.strip[0..24].humanize.delete("'") unless address.blank?

	    label = ZebraPrinter::StandardLabel.new
	    label.draw_barcode(40, 180, 0, 1, 5, 15, 120, false, "#{self.national_id}")    
	    label.draw_text("#{self.name.titleize}", 40, 30, 0, 2, 2, 2, false) #'           
	    label.draw_text("#{national_id_and_birthdate}#{sex}", 40, 80, 0, 2, 2, 2, false)        
	    label.draw_text("#{address}", 40, 130, 0, 2, 2, 2, false)
	    label.print(num)
	  end

	  def filing_number_label(num = 1)
	    file=self.filing_number
	    file_type=file.strip[3..4]
	    version_number=file.strip[2..2]
	    len=file.length - 5
	    number = Patient.print_filing_number(file)# file.strip[len..len] + "   " + file.strip[(len + 1)..(len + 2)]  + " " +  file.strip[(len + 3)..(file.length)]

	    label = ZebraPrinter::StandardLabel.new
	    label.draw_text("#{number}",75, 30, 0, 4, 4, 4, false)            
	    label.draw_text("Filing area #{file_type}",75, 150, 0, 2, 2, 2, false)            
	    label.draw_text("Version number: #{version_number}",75, 200, 0, 2, 2, 2, false)            
	    label.print(num)
	  end

	  def transfer_out_label(date = Date.today,destination="Unknown")
	    who_stage = self.reason_for_art_eligibility 
	    initial_staging_conditions = self.art_initial_staging_conditions
	   
	    label = ZebraPrinter::Label.new(776, 329, 'T')
	    label.line_spacing = 0
	    label.top_margin = 30
	    label.bottom_margin = 30
	    label.left_margin = 25
	    label.x = 25
	    label.y = 30
	    label.font_size = 3
	    label.font_horizontal_multiplier = 1
	    label.font_vertical_multiplier = 1
	   
	    # 25, 30
	    # Patient personanl data 
	    label.draw_multi_text("#{Location.current_health_center} transfer out label", {:font_reverse => true})
	    label.draw_multi_text("From #{Location.current_arv_code} to #{destination}", {:font_reverse => false})
	    label.draw_multi_text("ARV number: #{self.arv_number}", {:font_reverse => true})
	    label.draw_multi_text("Name: #{self.name} (#{self.sex.first})\nAge: #{self.age}", {:font_reverse => false})

	    # Print information on Diagnosis!
	    label.draw_multi_text("Diagnosis", {:font_reverse => true})
	    label.draw_multi_text("Reason for starting: #{self.reason_for_art_eligibility}", {:font_reverse => false})
	    label.draw_multi_text("Art start date: #{self.date_started_art.strftime("%d-%b-%Y") rescue nil}", {:font_reverse => false})
	    label.draw_multi_text("Other diagnosis:", {:font_reverse => true})
	# !!!! TODO
	    staging_conditions = ""
	    count = 1
	    initial_staging_conditions.each{|condition|
	     staging_conditions+= " (#{count+=1}) " unless staging_conditions.blank?
	     staging_conditions= "(#{count}) " if staging_conditions.blank?
	     staging_conditions+=condition
	    }
	    label.draw_multi_text("#{staging_conditions}", {:font_reverse => false})

	    # Print information on current status of the patient transfering out!
	    work = self.observations.find_last_by_concept_name("Is at work/school").to_short_s rescue nil
	    amb = self.observations.find_last_by_concept_name("Is able to walk unaided").to_short_s rescue nil
	    first_cd4_count = self.observations.find_first_by_concept_name("CD4 count")
	    last_cd4_count = self.observations.find_last_by_concept_name("CD4 count")
	    last_cd4 = "Last CD4: " + last_cd4_count.obs_datetime.strftime("%d-%b-%Y") + ": " + last_cd4_count.to_short_s.delete("=,Yes") rescue nil
	    first_cd4 = "First CD4: " + first_cd4_count.obs_datetime.strftime("%d-%b-%Y") + ": " + first_cd4_count.to_short_s.delete("=,Yes") rescue nil
	    label.draw_multi_text("Current Status", {:font_reverse => true})
	    label.draw_multi_text("#{work} #{amb}", {:font_reverse => false})
	    label.draw_multi_text("#{first_cd4}", {:font_reverse => false})
	    label.draw_multi_text("#{last_cd4}", {:font_reverse => false})
	 
	    # Print information on current treatment of the patient transfering out!
	    current_drugs = self.previous_art_drug_orders
      current_art_drugs = current_drugs.collect{|drug_name_quantity|drug_name_quantity.to_s} rescue nil
      current_art_drugs = current_art_drugs.collect{|drug_name|drug_name.split(":")[0]} rescue nil
	    drug_names = ""
	    count = 1
	    current_art_drugs.each{|name|
	     drug_names+= " (#{count+=1}) " unless drug_names.blank?
	     drug_names= "(#{count}) " if drug_names.blank?
	     drug_names+=name
	    } rescue nil

	    start_date = self.date_started_art.strftime("%d-%b-%Y") rescue nil
	    label.draw_multi_text("Current art drugs", {:font_reverse => true})
	    label.draw_multi_text("#{drug_names}", {:font_reverse => false})
	    label.draw_multi_text("Transfer out date:", {:font_reverse => true})
	    label.draw_multi_text("#{date.strftime("%d-%b-%Y")}", {:font_reverse => false})

	    label.print(1)
	  end
	  
	  def archived_filing_number_label(num=1)
	    patient_id = PatientIdentifier.find(:first, :conditions => ["voided = 1 AND identifier = ? AND patient_id <> ?",self.filing_number,self.id]).patient_id rescue nil
	    return nil if patient_id.blank?
	    patient = Patient.find(patient_id) #find the patient who have given up his/her filing number
	    filing_number = patient.archive_filing_number
	    return nil if filing_number.blank?

	    file= filing_number
	    file_type=file.strip[3..4]
	    version_number=file.strip[2..2]
	    len=file.length - 5
	    number= Patient.print_filing_number(file) #file.strip[len..len] + "   " + file.strip[(len + 1)..(len + 2)]  + " " +  file.strip[(len + 3)..(file.length)]
	    old_filing_number =  self.filing_number[5..-1].to_i.to_s rescue nil
	    
	    label = ZebraPrinter::StandardLabel.new
	    label.draw_text("#{number}",75, 30, 0, 4, 4, 4, true)            
	    label.draw_text("#{Location.current_arv_code} archive filing area",75, 150, 0, 2, 2, 2, false)            
	    label.draw_text("Version number: #{version_number}",75, 200, 0, 2, 2, 2, false)            
	    return label.print(num)
	  end
	  
	  def self.print_filing_number(number)
	   len = number.length - 5
	   return number[len..len] + "   " + number[(len + 1)..(len + 2)]  + " " +  number[(len + 3)..(number.length)]
	  end

## DRUGS
    def drug_dispensed_label(date=Date.today)
	    date=date.to_date
	    sex =  self.gender == "Female" ? "(F)" : "(M)"
	    next_appointment = self.next_appointment_date(date)
	    next_appointment_date="Next visit: #{next_appointment.strftime("%d-%b-%Y")}" unless next_appointment.nil?
	    symptoms = Array.new
	    weight=nil
      height=nil
	    prescription = DrugOrder.given_drugs_dosage(self.drug_orders_for_date(date))
	    amb=nil
	    work_sch=nil

      concept_names = Concept.find_by_name('Symptoms').answer_options.collect{|option| option.name}
      concept_names += Concept.find_by_name('Symptoms continued..').answer_options.collect{|option| option.name}
      concept_names += ["Weight","Height","Is at work/school","Is able to walk unaided"]
      concept_names.each{|concept_name|
        concept = Concept.find_by_name(concept_name)
        patient_observations = Observation.find(:all,:conditions => ["concept_id=? and patient_id=? and Date(obs.obs_datetime)=? and voided =0",concept.id,self.patient_id,date.to_date.strftime("%Y-%m-%d")],:order=>"obs.obs_datetime desc")
        case concept_name
          when "Is able to walk unaided"
            unless  patient_observations.first.nil?
              amb=patient_observations.first.answer_concept.name
              amb == "Yes" ? amb = "walking;" : amb = "not walking;"
            end
          
          when "Is at work/school"
            unless   patient_observations.first.nil?
              work_sch=patient_observations.first.answer_concept.name
              work_sch == "Yes" ? work_sch = "working;" : work_sch = "not working;"
            end

          when "Weight"
            weight=patient_observations.first.value_numeric.to_s + "kg;" unless patient_observations.first.nil?

          when "Height"
            height=patient_observations.first.value_numeric.to_s + "cm; " unless patient_observations.first.nil?

          else
            unless patient_observations.first.nil?
              ans = patient_observations.first.answer_concept.name
              symptoms << concept.short_name if ans.include?("Yes") # 'Yes', 'Yes unknow cause', 'Yes drug induced'
            end
        end
	    }

     height ||= ""
	   provider = self.encounters.find_by_type_name_and_date("ART Visit", date)
	   provider_name = provider.last.provider.username rescue nil
	   prescride_drugs = Hash.new()
	   prescride_drugs = Patient.addup_prescride_drugs(prescription)
	   visit_by="Both patient and guardian visit" if self.patient_and_guardian_present?(date)
     visit_by="Patient visit" if visit_by.blank? and self.patient_present?(date) and !self.guardian_present?(date)
	   visit_by="Guardian visit" if visit_by.blank? and self.guardian_present?(date) and !self.patient_present?(date)
	   provider_name = User.current_user.username if provider_name.blank?
	   symptoms = symptoms.reject{|s|s.blank?}
     symptoms.length > 0 ? symptom_text = symptoms.join(', ') : symptom_text = 'no symptoms;'
     adherence = ""#self.adherence_report(previous_visit_date)
     drugs_given = prescride_drugs.to_s rescue nil
     current_outcome = Patient.visit_summary_out_come(self.outcome.name) rescue nil

     label = ZebraPrinter::StandardLabel.new
     label.font_size = 3
     label.number_of_labels = 2
     label.draw_multi_text("#{self.name} (#{self.sex.first}) #{self.print_national_id}",{:font_reverse =>false})
     label.draw_multi_text("#{date.strftime("%d-%b-%Y")} #{visit_by} (#{provider_name.upcase})",{:font_reverse =>false})
     label.draw_multi_text("Vitals: #{height}#{weight} #{amb} #{work_sch} #{symptom_text} #{adherence}",{:font_reverse =>false, :hanging_indent => 8})
     label.draw_multi_text("Drugs:#{drugs_given}",{:font_reverse =>false})
#TODO, temporarily commented out until appt dates is fixed     label.draw_multi_text("Outcome: #{current_outcome}, #{next_appointment_date}",{:font_reverse => false})
     label.draw_multi_text("Outcome: #{current_outcome}",{:font_reverse => false})
	   return label.print(2)
	  end
    
    def self.visit_summary_out_come(outcome)
      return if outcome.blank?
      return "On ART at #{Location.current_arv_code}" if outcome == "On ART"
      return outcome
    end
     
## DRUGS
	  def self.addup_prescride_drugs(prescriptions)
     return if prescriptions.blank?
     prescribe_drugs=Hash.new()
     prescriptions.each{|prescription|
      (drug_name, frequency, dose_amount) =  prescription.split(/, */)
      prescribe_drugs[drug_name] = {"Morning" => 0, "Noon" => 0, "Evening" => 0} if prescribe_drugs[drug_name].nil?
      prescribe_drugs[drug_name].keys.each{ |time|
       prescribe_drugs[drug_name][time] += dose_amount.to_f if frequency.match(/#{time}/i)
      }
     }

     drugs_given = Array.new()
     prescribe_drugs.each do |drug_name,dosing_frequency|
      dosage = self.print_dosage(dosing_frequency)
      #drugs_given += "#{drug_name} (#{dosing_frequency["Morning"]} - #{dosing_frequency["Noon"]} - #{dosing_frequency["Evening"]})\n"
      drugs_given << "\n- #{drug_name}" 
      #drugs_given << " #{drug_name} #{dosage};" 
     end
     return drugs_given.uniq.sort
	  end

    def self.print_dosage(dosing_frequency)
      return nil
      dosage_results = Array.new()
      morning = dosing_frequency["Morning"].to_s
      noon = dosing_frequency["Noon"].to_s
      evening = dosing_frequency["Evening"].to_s

      morning = morning[-2..morning.length] == ".0" ? morning[0..-3] : morning
      noon = noon[-2..noon.length] == ".0" ? noon[0..-3] : noon
      evening = evening[-2..evening.length] == ".0" ?  evening[0..-3] : evening


      return "( _ - _ - _ )" if morning == "0" and noon == "0" and evening == "0"
      ("(#{self.to_fraction(morning)} - #{self.to_fraction(noon)} - #{self.to_fraction(evening)})\n")
    end

    def self.to_fraction(number)
      return number if !number.include?(".")
      whole_number = number.split(".").first
      decimal_number = "0.#{number.split(".").last}"
      return "(#{decimal_number.to_f.to_r.to_s})" if whole_number == "0"
      "#{whole_number} (#{decimal_number.to_f.to_r.to_s})"
    end

	  def initial_weight
	     initial_weight = self.observations.find_first_by_concept_name("Weight")
	     return initial_weight.value_numeric unless initial_weight.nil? 
	  end

	  def set_initial_weight(weight, date)
	    weight = weight.to_f
	    raise "Patient already has initial_weight" unless self.initial_weight.nil?
	    observation = Observation.new
	    observation.patient = self
	    observation.concept = Concept.find_by_name("Weight")
	    observation.value_numeric = weight
	    observation.obs_datetime = date
	    observation.save
	  end

	  def initial_height
	     initial_height = self.observations.find_first_by_concept_name("Height")
	     return initial_height.value_numeric unless initial_height.nil? 
	  end

	  def set_initial_height(height, date)
	    height = height.to_f
	    raise "Patient already has initial_height" unless self.initial_height.nil?
	    observation = Observation.new
	    observation.patient = self
	    observation.concept = Concept.find_by_name("Height")
	    observation.value_numeric = height
	    observation.obs_datetime = date
	    observation.save
	  end

	  def current_place_of_residence
	    return self.person_address
	  end

	  def current_place_of_residence=(name)
	    patient_addresses = self.patient_addresses
	    patient_addresses = PatientAddress.new
	    patient_addresses.patient = self
	    patient_addresses.city_village = name
	    patient_addresses.save
	  end
	  
	  def set_national_id
	    #return if self.national_id
	    identifier_type_id = PatientIdentifierType.find_by_name("National id").patient_identifier_type_id
	    return nil if identifier_type_id.nil?
	    PatientIdentifier.create!(:identifier => Patient.next_national_id, :identifier_type => identifier_type_id, :patient_id => self.id)
  end
  
  def self.next_filing_number
   return PatientIdentifier.get_next_patient_identifier("Filing number")
  end
 
  def self.next_archive_filing_number
   return PatientIdentifier.get_next_patient_identifier("Archived filing number")
  end 
   
  def needs_filing_number?
   if self.filing_number
    return true if self.archive_filing_number
     return false
    else
     return true 
   end
  end

  def set_filing_number
    return unless self.needs_filing_number?
    filing_number_identifier_type = PatientIdentifierType.find_by_name("Filing number")

    if self.archive_filing_number 
     #voids the record- if patient has a dormant filing number
     current_archive_filing_number = self.patient_identifiers.find_first_by_identifier_type(PatientIdentifierType.find_by_name("Archived filing number").id)
     current_archive_filing_number.voided = 1
     current_archive_filing_number.void_reason = "patient assign new active filing number"
     current_archive_filing_number.voided_by = User.current_user
     current_archive_filing_number.date_voided = Time.now()
     current_archive_filing_number.save
    end

    next_filing_number = Patient.next_filing_number # gets the new filing number! 
    next_patient_to_archived = Patient.next_filing_number_to_be_archived(next_filing_number) # checks if the the new filing number has passed the filing number limit...

    unless next_patient_to_archived.blank?
     Patient.archive_patient(next_patient_to_archived,self) # move dormant patient from active to dormant filing area
     next_filing_number = Patient.next_filing_number # gets the new filing number!
    end

    filing_number= PatientIdentifier.new() 
    filing_number.patient_id = self.id
    filing_number.identifier_type = filing_number_identifier_type.patient_identifier_type_id
    filing_number.identifier = next_filing_number
    filing_number.save

  end

  def set_archive_filing_number
   return if self.archive_filing_number
   archive_number = Patient.next_archive_filing_number 
   new_archive_number = PatientIdentifier.new()
   new_archive_number.patient = self
   new_archive_number.identifier_type = PatientIdentifierType.find_by_name("Archived filing number").id
   new_archive_number.date_created = Time.now()
   new_archive_number.creator = User.current_user.id
   new_archive_number.identifier = archive_number
   new_archive_number.save
  end
  
  def self.next_filing_number_to_be_archived(filing_number)
   global_property_value = GlobalProperty.find_by_property("filing_number_limit").property_value rescue "4000"
   if (filing_number[5..-1].to_i >= global_property_value.to_i)
    all_filing_numbers = PatientIdentifier.find(:all, :conditions =>["identifier_type = ? and voided= 0",PatientIdentifierType.find_by_name("Filing number").id],:group=>"patient_id")
    patients_id = all_filing_numbers.collect{|i|i.patient_id}
    return Encounter.find_by_sql(["select patient_id from (SELECT max(encounter_datetime) as encounter_datetime,patient_id FROM encounter  where patient_id in (?) group by patient_id) as T ORDER BY encounter_datetime asc limit 1",patients_id]).first.patient_id rescue nil
   end
  end

  def Patient.archive_patient(patient_to_be_archived_id,current_patient)
    patient = Patient.find(patient_to_be_archived_id)
    filing_number_identifier_type = PatientIdentifierType.find_by_name("Archived filing number")
    next_filing_number = Patient.next_archive_filing_number

    filing_number= PatientIdentifier.new() 
    filing_number.patient = patient 
    filing_number.identifier_type = filing_number_identifier_type.patient_identifier_type_id  
    filing_number.identifier = next_filing_number
    filing_number.save

   #void current filing number
    current_filing =  PatientIdentifier.find(:first,:conditions=>["patient_id=? and identifier_type=? and voided = 0",patient.id,PatientIdentifierType.find_by_name("Filing number").id])
    if current_filing
     current_filing.voided = 1
     current_filing.void_reason = "Archived"
     current_filing.date_voided = Time.now()
     current_filing.save
    end
   
    #the following code creates an encounter so that the the current patient
    #being given a new active filing number should have a new encounter with
    #the current date_time!!
    #the "current encounter date_time" will ensure that the patients' latest
    #encounter_datetime is "up to date"....
    new_number_encounter = Encounter.new()
    new_number_encounter.patient_id = current_patient.id
    new_number_encounter.encounter_type = EncounterType.find_by_name("Barcode scan").id
    new_number_encounter.encounter_datetime = Time.now()
    new_number_encounter.provider_id = User.current_user.id
    new_number_encounter.creator = User.current_user.id
    new_number_encounter.save!
  end

  def self.next_national_id
    health_center_id = GlobalProperty.find_by_property("current_health_center_id").property_value
    national_id_version="1"
    national_id_prefix = "P#{national_id_version}#{health_center_id.rjust(3,"0")}"

    national_id_type = PatientIdentifierType.find_by_name("National id").patient_identifier_type_id

    last_national_id = PatientIdentifier.find(:first,:order=>"identifier desc", :conditions => ["identifier_type = ? AND left(identifier,5)= ?",national_id_type,national_id_prefix])
    unless last_national_id.nil?
       last_national_id_number= last_national_id.identifier
    else
       last_national_id_number = "0"
    end

    next_number = (last_national_id_number[5..-2].to_i+1).to_s.rjust(7,"0") 
    new_national_id_no_check_digit = "#{national_id_prefix}#{next_number}"
    check_digit = PatientIdentifier.calculate_checkdigit(new_national_id_no_check_digit[1..-1])
    return "#{new_national_id_no_check_digit}#{check_digit}" 
  end

  def Patient.validates_national_id(number)
   number_to_be_checked = number[0..11]
   check_digit = number[-1..-1].to_i
   valid_check_digit =PatientIdentifier.calculate_checkdigit(number_to_be_checked)
   return "id should have 13 characters" if number.length != 13
   return "valid id" if valid_check_digit == check_digit
   return "check digit is wrong" if valid_check_digit != check_digit and number.match(/\d+/).to_s.length == 12
   return "invalid id"
  end

  def landmark
    self.patient_location_landmark
  end

  def landmark=(value)
    self.patient_location_landmark=(value)
  end

  def hiv_test_date
    date_of_first_positive_hiv_test = self.observations.find_by_concept_name("Date of first positive HIV test")
    date_of_first_positive_hiv_test.first.value_datetime unless date_of_first_positive_hiv_test.empty?
  end

  def set_hiv_test_date(date)
    observation = Observation.new
    observation.patient = self
    observation.concept = Concept.find_by_name("Date of first positive HIV test")
    observation.value_datetime = date
    observation.obs_datetime = Date.today
    observation.save
  end

  def sex=(sex)
    self.gender = sex
  end

  def sex
    self.gender
  end

  def void(reason)
    # make sure User.current_user is set
    self.voided = true
    self.voided_by = User.current_user.id unless User.current_user.nil?
    self.void_reason = reason
    self.save
  end
 
    #HL7 elements
  def facility
   return GlobalProperty.find(:all, :conditions =>["property = ?","current_health_center_id"]).first.property_value
  end

  def to_patient_hl7
    require 'ruby-hl7'
    require 'socket'

    # create the empty hl7 message
    msg = HL7::Message.new

    # create an empty MSH segment
    msh = HL7::Message::Segment::MSH.new 
    evn = HL7::Message::Segment::EVN.new 
    pid = HL7::Message::Segment::PID.new 
    pv1 = HL7::Message::Segment::PV1.new 
    obr = HL7::Message::Segment::OBR.new 
    obx = HL7::Message::Segment::OBX.new

    # create an empty NTE segment
   # nte = HL7::Message::Segment::NTE.new
    msg << msh # add the MSH segment to our message
    #msg << nte  # add the NTE segment to our message
   
    # let's fill in some fields using pre-defined aliases
    msh.enc_chars = "^~\&"
    msh.sending_app = "Baobab Health partenership"
    msh.sending_facility = GlobalProperty.find(:all, :conditions =>["property = ?","current_health_center_id"]).first.property_value
    msh.recv_facility = "MOH"
    msh.recv_app = "0999"
    msh.date =  Date.today
    msh.message_type = "ZMW^P01^ZMW_P01"
    msh.time =  Time.now()
   # msh.message_control_id = ""
    msh.processing_id = "PT"
    msh.version_id = "2.5"
    msh.country_code = "MWI"
    msh.charset = "UTF-8"
    msh.principal_language_of_message = "English"

    #nte.comment = "my message rocks, ruby-hl7 is great"

    # let's create our own on-the-fly segment (NK1 is not implemented in code)
    seg = HL7::Message::Segment::Default.new
    seg.e0 = "SFT"             # define the segment's name
    seg.e1 = "Baobab Health partnerhip"   # define it's first field
    seg.e2 = "1.000" # define it's second field
    seg.e3 = "Baobab Anti-retroviral system" # define it's second field
    seg.e4 = "Binary ID" # define it's second field
    seg.e5 = "Installation Date"
    
   # patient_obj = self

    msg << seg  # add the new segment to the message
    msg << evn  # add the new segment to the message
    msg << pid  # add the new segment to the message
 
    evn.recorded_date = Date.today
    evn.event_facility = GlobalProperty.find(:all, :conditions =>["property = ?","current_health_center_id"]).first.property_value
     
    pid.set_id = "1"
    pid.patient_id = self.patient_id
    pid.patient_id_list = self.patient_id 
    pid.patient_name = self.name 
    pid.patient_dob = self.birthdate.year
    
    if self.gender == "Male"
     pid.admin_sex = "M"
    else
     pid.admin_sex = "F"
    end  
    
    pid.address = self.patient_addresses.last.city_village
    pid.phone_home = self.get_identifier("Home phone number")
    pid.death_date = self.death_date
  
    if self.outcome_status == "Died"
      pid.death_indicator = "D"
    else
      pid.death_indicator = "N"
    end
    
    nk1 = HL7::Message::Segment::Default.new
    nk1.e0 = "NK1"
    nk1.e1 = "1"
    nk1.e2 = self.art_guardian.name
    
    msg << nk1

    #patient visit information; including observations
    #aggregate visits
    #should visits be broken down into one visit
    #HL7 definition says that definition is based on 
        visit_number = 1
        encounter_dates = self.encounters.collect{|e|e.encounter_datetime.to_date}.uniq 
        first_encounter = encounter_dates.reverse.pop
        pv1.set_id = visit_number
        pv1.assigned_location =  GlobalProperty.find(:all, :conditions =>["property = ?","current_health_center_id"]).first.property_value
        pv1.admit_date = first_encounter.strftime("%Y%m%d")
        
        msg << pv1

    encounter_dates.each{|ed|
     visit_number += 1
     pv1.set_id = visit_number 
     pv1.assigned_location =  GlobalProperty.find(:all, :conditions =>["property = ?","current_health_center_id"]).first.property_value
     pv1.admit_date = ed.strftime("%Y%m%d")
     msg << pv1
       self.encounters.find_by_date(ed).each{|encounter| 
        obr.set_id = visit_number
        obr.universal_service_id = "CurrentART"
        obr.observation_date = ed
        msg << obr
        #Weight  
        obx.set_id = visit_number
        obx.value_type = "NM"
        obx.observation_id ="18833-4"
        obx.observation_value = encounter.find_by_type_name("Height/Weight").observations.find_by_concept_name("Weight")
        obx.units = "KG"
        obx.observation_result_status = "F"
        obx.observation_date = encounter.find_by_type_name("Height/Weight").observations.find_by_concept_name("Weight").obs_datetime.strftime("%Y%m%d")
        #Height
        obx.set_id = visit_number + 1
        obx.value_type = "NM"
        obx.observation_id = "K00237"
        obx.observation_value = encounter.find_by_type_name("Height/Weight").observations.find_by_concept_name("Height")
        obx.units = "cm"
        obx.observation_result_status = "F"
        obx.observation_date = encounter.find_by_type_name("Height/Weight").observations.find_by_concept_name("Height").obs_datetime.strftime("%Y%m%d")
        obx.set_id = visit_number + 2
        obx.value_type = ""
        obx.observation_id = "K00201^ART Prior Treatment"
        obx.observation_value = encounter.find_by_type_name("HIV First visit").observations.find_by_concept_name("Ever received ART")
        
        
       }
     }

    puts msg
 
  end  
  
  
     
  def complete_visit?(date = Date.today)
    encounter_types_for_day = self.encounters.find_by_date(date).collect{|encounter|encounter.name}
    expected_encounter_types = ["ART Visit", "Give drugs", "HIV Reception", "Height/Weight"]
    return true if (expected_encounter_types - encounter_types_for_day).empty?

    puts encounter_types_for_day.join(", ") unless encounter_types_for_day.blank? #some days will not have any encounters.
    return false
  end

  #HL7 functions
  #HL7 functions
 def weight_on_date  
  begin
       weight = self.encounters.find_by_type_name_and_date("Height/Weight",date).first.observations.find_by_concept_name("Weight").first.value_numeric
    rescue ActiveRecord::RecordNotFound
        return nil
    end 
        return weight
  end	  

  def height_on_date(date = Date.today)
    begin
       height = self.encounters.find_by_type_name_and_date("Height/Weight",date).first.observations.find_by_concept_name("Height").first.value_numeric
    rescue ActiveRecord::RecordNotFound
        return nil
    end 
        return height
  end	  

   def ever_received_art
    hiv_first_visit = self.encounters.find_first_by_type_name("HIV First visit")
   begin 
    yes_concept = Concept.find_by_name("Yes")
    prior_art = hiv_first_visit.observations.find_last_by_concept_name("Ever received ART").answer_concept == yes_concept
    return "Prior ARV treatment" if prior_art == yes_concept
   rescue	    
    return "No prior ARV treatment"
   end 
  end

  def district_of_initiation
    return false unless self.hiv_patient?
    hiv_first_visit = self.encounters.find_first_by_type_name("HIV First visit")
    return false if hiv_first_visit.blank?
  #not a transfer in, therefore default district to location of test
    if  hiv_first_visit.observations.find_last_by_concept_name("Ever received ART").nil? or  hiv_first_visit.observations.find_last_by_concept_name("Ever registered at ART clinic").blank?
     return self.encounters.find_by_type_name("HIV first visit").first.observations.find_by_concept_name("Location of first positive HIV test").first
   end	   
    yes_concept = Concept.find_by_name("Yes")
    #tranfer in patient
    if hiv_first_visit.observations.find_last_by_concept_name("Ever received ART").answer_concept == yes_concept and hiv_first_visit.observations.find_last_by_concept_name("Ever registered at ART clinic").answer_concept == yes_concept
    return self.encounters.find_by_type_name("HIV first visit").first.observations.find_by_concept_name("Site transfered from").first
   end	    
  end

  def first_cd4_count
   obs = Observation.find(:all,:conditions => ["concept_id=? and patient_id=?",(Concept.find_by_name("CD4 Count").id),self.patient_id],:order=>"obs.obs_datetime asc").first
   return nil if obs.nil?
   value_modifier = obs.value_modifier 
   cd4_count= obs
   return cd4_count
 end

  def hl7_arv_number
    begin
      self.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("Arv national id").id) 
    rescue
     return nil
   end
  end

  def date_of_starting_first_line_alt
    begin
      return  self.observations.find_by_concept_name("ARV First line regimen alternatives")
    rescue
      return nil
    end	    
  end	  
#End of HL 7 functions


  def valid_visit?(date = Date.today)
    encounters_types_for_day = self.encounters.find_by_date(date).collect{|encounter|encounter.name}
    expected_encounter_types = ["ART Visit", "Give drugs", "HIV Reception", "Height/Weight"]

    if encounters_types_for_day.include?("Give drugs") and not (["ART Visit", "HIV Reception"] - encounters_types_for_day).empty?
      print self.national_id.to_s + " " +self.name + " " 
      puts encounters_types_for_day.join(", ")
      return false
    end

    return true
  end
  
  def last_art_visit_date(date = Date.today) 
   date = date.to_s.to_time
   encounter_types_id = EncounterType.find_by_name("ART Visit").id
   return Encounter.find(:first,
          :conditions=>["patient_id=? and encounter_type=? and encounter_datetime < ?",
          self.id,encounter_types_id,date],:order=> "encounter_datetime desc").encounter_datetime rescue nil
  end

  def needs_cd4_count?(date = Date.today)
   last_visit_date = self.last_art_visit_date(date)
   date_when_started_art = self.date_started_art
   return false if date_when_started_art.blank?
   return false if last_visit_date.blank?
   return false if date_when_started_art > date.to_time
   duration = GlobalProperty.find_by_property("months_to_remind_cd4_count").property_value.to_i rescue 6
   last_reminder_date = date_when_started_art

   last_cd4_by_patient = LabSample.last_cd4_by_patient(self.id_identifiers)
   unless last_cd4_by_patient.blank?
     last_cd4_date = last_cd4_by_patient.TESTDATE.to_time
     return false if (date.to_time < last_cd4_date)
     return (((date.to_time - last_cd4_date)/1.month).floor).months >= duration.months
   end

   while last_reminder_date < date.to_time
    last_reminder_date = (last_reminder_date+= duration.months)
   end
   last_reminder_date = (last_reminder_date - duration.months)
   date_boundary_lowest =  last_reminder_date - 10.day
   return last_visit_date < date_boundary_lowest
  end

  def self.empty_cohort_data_hash
    cohort_values = Hash.new(0)
    cohort_values["regimen_types"] = Hash.new
    cohort_values["occupations"] = Hash.new
    cohort_values["start_reasons"] = Hash.new
    cohort_values["outcome_statuses"] = Hash.new    
    cohort_values["messages"] = Array.new
    return cohort_values
  end

  def valid_for_cohort?(start_date, end_date)
    return false if self.voided?
    date_started_art = self.date_started_art
    return false if date_started_art.blank?
    return false unless self.date_started_art.to_date.between?(start_date, end_date)
    return true
  end

  def cohort_data(start_date, end_date, cohort_values=nil)
    @quarter_start = start_date
    @quarter_end = end_date

    if cohort_values.nil?
      cohort_values = Patient.empty_cohort_data_hash
    end

    Report.cohort_patient_ids[:all] << self.id

    patient_started_as_adult = true

    cohort_values["all_patients"] += 1 
      if self.gender == "Male"
        cohort_values["male_patients"] += 1
      else
        cohort_values["female_patients"] += 1
      end
      if self.child_at_initiation?
        cohort_values["child_patients"] += 1
        patient_started_as_adult = false
      else
        cohort_values["adult_patients"] += 1
      end
      
      #njero qech debug
      #f = this_patient.observations.find_by_concept_name("Date of ART initiation").first
      #@art_inits ||= ""
      #@art_inits += "\n#{this_patient.id}/#{f.value_datetime if f}"

      patient_occupation = self.occupation
      patient_occupation ||= "Other" 
      #patient_occupation = patient_occupation.capitalize
      patient_occupation = patient_occupation.downcase
      patient_occupation = 'soldier/police' if patient_occupation =~ /police|soldier/
      if cohort_values["occupations"].has_key?(patient_occupation) then
        cohort_values["occupations"][patient_occupation] += 1
        Report.cohort_patient_ids[:occupations][patient_occupation] << self.id
      else
        cohort_values["occupations"][patient_occupation] = 1
        Report.cohort_patient_ids[:occupations][patient_occupation] = [self.id]
      end

      reason_for_art_eligibility = self.reason_for_art_eligibility
      start_reason = reason_for_art_eligibility ? reason_for_art_eligibility.name : "Unknown"
      start_reason = 'WHO Stage 4' if start_reason == 'WHO stage 4 adult' or start_reason == 'WHO stage 4 peds'
      start_reason = 'WHO Stage 3' if start_reason == 'WHO stage 3 adult' or start_reason == 'WHO stage 3 peds'
      if cohort_values["start_reasons"].has_key?(start_reason) then
        cohort_values["start_reasons"][start_reason] += 1
        Report.cohort_patient_ids[:start_reasons][start_reason] << self.id
      else
        cohort_values["start_reasons"][start_reason] = 1
        Report.cohort_patient_ids[:start_reasons][start_reason] = [self.id]
      end

      cohort_visit_data = self.get_cohort_visit_data(@quarter_start, @quarter_end)                      
      if cohort_visit_data["Extrapulmonary tuberculosis (EPTB)"] == true
        cohort_values["start_cause_EPTB"] += 1
        Report.cohort_patient_ids[:start_reasons]['start_cause_EPTB'] ||= []
        Report.cohort_patient_ids[:start_reasons]['start_cause_EPTB'] << self.id
      elsif cohort_visit_data["PTB within the past 2 years"] == true
        cohort_values["start_cause_PTB"] += 1
        Report.cohort_patient_ids[:start_reasons]['start_cause_PTB'] ||= []
        Report.cohort_patient_ids[:start_reasons]['start_cause_PTB'] << self.id
      elsif cohort_visit_data["Active Pulmonary Tuberculosis"] == true 
        cohort_values["start_cause_APTB"] += 1
        Report.cohort_patient_ids[:start_reasons]['start_cause_APTB'] ||= []
        Report.cohort_patient_ids[:start_reasons]['start_cause_APTB'] << self.id
      end
      if cohort_visit_data["Kaposi's sarcoma"] == true
        cohort_values["start_cause_KS"] += 1
        Report.cohort_patient_ids[:start_reasons]['start_cause_KS'] ||= []
        Report.cohort_patient_ids[:start_reasons]['start_cause_KS'] << self.id
      end
      pmtct_obs = self.observations.find_by_concept_name("Referred by PMTCT").last
      if pmtct_obs and pmtct_obs.value_coded == 3
        cohort_values["pmtct_pregnant_women_on_art"] +=1
        Report.cohort_patient_ids[:start_reasons]['pmtct_pregnant_women_on_art'] ||= []
        Report.cohort_patient_ids[:start_reasons]['pmtct_pregnant_women_on_art'] << self.id
      end
      
      outcome_status = self.cohort_outcome_status(@quarter_start, @quarter_end)
=begin
      if cohort_values["outcome_statuses"].has_key?(outcome_status) then
        cohort_values["outcome_statuses"][outcome_status] += 1
      else
        cohort_values["outcome_statuses"][outcome_status] = 1
      end
=end
			last_visit_datetime = cohort_visit_data["last_encounter_datetime"]
      
      if outcome_status == "Died" 
        cohort_values["dead_patients"] += 1
        Report.cohort_patient_ids[:outcome_data]['died'] ||= []
        Report.cohort_patient_ids[:outcome_data]['died'] << self.id
        unless self.death_date.blank?
          art_start_date = self.date_started_art
          death_date = self.death_date
          mins_to_months = 60*60*24*7*4 # get 4 week months from minutes
          months_of_treatment = 0
          months_of_treatment = ((death_date.to_time - art_start_date.to_time)/mins_to_months).ceil unless art_start_date.nil?
          if months_of_treatment <= 1  
            cohort_values["died_1st_month"] += 1 
            Report.cohort_patient_ids[:of_those_who_died]['month1'] ||= []
            Report.cohort_patient_ids[:of_those_who_died]['month1'] << self.id
          elsif months_of_treatment == 2  
            cohort_values["died_2nd_month"] += 1
            Report.cohort_patient_ids[:of_those_who_died]['month2'] ||= []
            Report.cohort_patient_ids[:of_those_who_died]['month2'] << self.id
          elsif months_of_treatment == 3  
            cohort_values["died_3rd_month"] += 1
            Report.cohort_patient_ids[:of_those_who_died]['month3'] ||= []
            Report.cohort_patient_ids[:of_those_who_died]['month3'] << self.id
          elsif months_of_treatment > 3 
            cohort_values["died_after_3rd_month"] += 1
            Report.cohort_patient_ids[:of_those_who_died]['after_month3'] ||= []
            Report.cohort_patient_ids[:of_those_who_died]['after_month3'] << self.id
          end
        else
          cohort_values["messages"].push "Patient id #{self.id} has the outcome status 'Died' but no death date is set"  
        end  
      elsif outcome_status.include? "Transfer Out"
        cohort_values["transferred_out_patients"] += 1 
        Report.cohort_patient_ids[:outcome_data]['transferred_out'] ||= []
        Report.cohort_patient_ids[:outcome_data]['transferred_out'] << self.id
      elsif outcome_status == "ART Stop" 
        cohort_values["art_stopped_patients"] += 1  
        Report.cohort_patient_ids[:outcome_data]['stopped'] ||= []
        Report.cohort_patient_ids[:outcome_data]['stopped'] << self.id
      elsif last_visit_datetime.nil? or (@quarter_end - last_visit_datetime.to_date).to_i > 90  
        cohort_values["defaulters"] += 1 
        Report.cohort_patient_ids[:outcome_data]['defaulted'] ||= []
        Report.cohort_patient_ids[:outcome_data]['defaulted'] << self.id
      elsif outcome_status == "Alive and on ART" || outcome_status == "On ART"
        cohort_values["alive_on_ART_patients"] += 1 
        Report.cohort_patient_ids[:outcome_data]['on_art'] ||= []
        Report.cohort_patient_ids[:outcome_data]['on_art'] << self.id
        regimen_type = self.cohort_last_art_regimen(@quarter_start, @quarter_end)
        if (regimen_type)
          cohort_values["regimen_types"][regimen_type] ||= 0
          cohort_values["regimen_types"][regimen_type] += 1
          Report.cohort_patient_ids[:outcome_data][regimen_type] ||= []
          Report.cohort_patient_ids[:outcome_data][regimen_type] << self.id
          if cohort_visit_data["Is able to walk unaided"] == true
            cohort_values["ambulatory_patients"] += 1
            Report.cohort_patient_ids[:of_those_on_art]['ambulatory'] ||= []
            Report.cohort_patient_ids[:of_those_on_art]['ambulatory'] << self.id
          end
          if cohort_visit_data["Is at work/school"] == true
            cohort_values["working_patients"] += 1
            Report.cohort_patient_ids[:of_those_on_art]['working'] ||= []
            Report.cohort_patient_ids[:of_those_on_art]['working'] << self.id
          end

          if patient_started_as_adult and regimen_type == "ARV First line regimen" and not cohort_visit_data["Pill count"].nil?
            cohort_values["on_1st_line_with_pill_count_adults"] += 1 
            Report.cohort_patient_ids[:outcome_data]['on_1st_line_with_pill_count_adults'] ||= []
            Report.cohort_patient_ids[:outcome_data]['on_1st_line_with_pill_count_adults'] << self.id
            if cohort_visit_data["Pill count"] <= 8
              cohort_values["adherent_patients"] += 1
              Report.cohort_patient_ids[:outcome_data]['adherent'] ||= []
              Report.cohort_patient_ids[:outcome_data]['adherent'] << self.id
            end
          end
        else
          cohort_values['regimen_types']['Unknown'] ||= 0
          cohort_values['regimen_types']['Unknown'] += 1
        end            

        # Side effects
        side_effect_found = false
        if cohort_visit_data["Peripheral neuropathy"] or cohort_visit_data['Leg pain / numbness']
          cohort_values["peripheral_neuropathy_patients"] += 1
          side_effect_found = true
        end
        if cohort_visit_data["Hepatitis"] or cohort_visit_data["Jaundice"]
          cohort_values["hepatitis_patients"] += 1
          side_effect_found = true
        end
        if cohort_visit_data["Skin rash"]
          cohort_values["skin_rash_patients"] += 1
          side_effect_found = true
        end
        if cohort_visit_data["Lactic acidosis"]
          cohort_values["lactic_acidosis_patients"] += 1
          side_effect_found = true
        end
        if cohort_visit_data["Lipodystrophy"]
          cohort_values["lipodystropy_patients"] += 1 if cohort_visit_data["Lipodystrophy"]
          side_effect_found = true
        end
        if cohort_visit_data["Anaemia"]
          cohort_values["anaemia_patients"] += 1 if cohort_visit_data["Anaemia"]
          side_effect_found = true
        end
        if cohort_visit_data["Other side effect"] or cohort_visit_data['Other symptom']
          cohort_values["other_side_effect_patients"] += 1
          side_effect_found = true
        end
        if side_effect_found
          Report.cohort_patient_ids[:of_those_on_art]['side_effects'] ||= []
          Report.cohort_patient_ids[:of_those_on_art]['side_effects'] << self.id
        end
      end
      return cohort_values

  end

  def destroy_patient 
   self.encounters.each{|en|en.observations.each{|ob|ob.destroy}}
   self.encounters.each{|en|en.destroy}
   unless self.people.blank?
    self.people.each{|person|person.destroy}
   end	   
   
   unless self.observations.blank?
    self.observations.each{|person|person.destroy}
   end	   
   unless self.patient_programs.blank?
    self.patient_programs.each{|p|p.destroy}
   end	   
   self.destroy
  end
 
  # TODO: DRY!!!
  # This method should return self.encounters.last or vicerversa
  def last_encounter_by_patient
   return Encounter.find(:first, :conditions =>["patient_id = ?",self.id],:order =>"encounter_datetime desc") rescue nil
  end

  def active_patient?
	 months = 18.months
   patient_last_encounter_date = self.last_encounter_by_patient.encounter_datetime rescue nil
   return true if patient_last_encounter_date.blank?

   if (Time.now - (patient_last_encounter_date) >= months)
     return false
   else
     return true   
   end
  end

  def id_identifiers
    identifier_type = "Legacy pediatric id","National id","Legacy national id" 
    identifier_types = PatientIdentifierType.find(:all,:conditions=>["name IN (?)",identifier_type]).collect{|id|id.patient_identifier_type_id} rescue nil
    return PatientIdentifier.find(:all,:conditions=>["patient_id=? and identifier_type IN (?)",self.id,identifier_types]).collect{|identifiers|identifiers.identifier} rescue nil
  end
  
  def detail_lab_results(test_name=nil)
    test_type = LabPanel.get_test_type(test_name)
    return if test_type.blank?
    patient_ids = self.id_identifiers 
    return LabSample.lab_trail(patient_ids,test_type)
  end
  
  def available_lab_results
    patient_ids = self.id_identifiers 
    all_patient_samples = LabSample.find(:all,:conditions=>["patientid IN (?)",patient_ids],:group=>"Sample_ID").collect{|sample|sample.Sample_ID} rescue nil
    available_test_types = LabParameter.find(:all,:conditions=>["Sample_Id IN (?)",all_patient_samples],:group=>"TESTTYPE").collect{|types|types.TESTTYPE} rescue nil
    available_test_types = LabTestType.find(:all,:conditions=>["TestType IN (?)",available_test_types]).collect{|n|n.Panel_ID} rescue nil
    return if available_test_types.blank?
    return LabPanel.test_name(available_test_types) 
  end
  
  def detailed_lab_results_to_display(available_results = Hash.new())
   return if available_results.blank?
   lab_results_to_display = Hash.new()
   available_results.each do |date,lab_result |
    test_date = date.to_s.to_date.strftime("%d-%b-%Y")
    lab_results = lab_result.flatten
    lab_results.each{|result|
      name = LabTestType.test_name(result.TESTTYPE)
      test_value = result.TESTVALUE
      test_result = result.Range + " " + test_value.to_s if !result.Range == "="
      test_result = test_value if test_result.blank?
      lab_results_to_display[name] << ":" + test_date.to_s + ":" + test_result.to_s unless lab_results_to_display[name].blank?
      lab_results_to_display[name] = test_date.to_s + ":" + test_result.to_s if lab_results_to_display[name].blank?
    }
   end
   return lab_results_to_display
  end
  
  def available_test_dates(detail_lab_results,return_dates_only=false)
    available_dates = Array.new()
    date_th =nil
    html_tag = Array.new()
    html_tag_to_display = nil
    detail_lab_results.each do |name,lab_result |
      results = lab_result.split(":").enum_slice(2).map
      results.each{|result|
        available_dates << result.first if !available_dates.blank? and !available_dates.include?(result.first) rescue nil
        available_dates << result.first  if available_dates.blank?
      }
    end 
   
    return available_dates.reject{|result|result.blank?}.uniq.sort{|a,b| a.to_date<=>b.to_date} if return_dates_only == true

    available_dates.reject{|result|result.blank?}.uniq.sort{|a,b| a.to_date<=>b.to_date}.each{|date|
      dates = date.to_s
      dates = "Unknown" if date.to_s == "01-Jan-1900"
      date_th+= "<th>#{dates}</th>" unless date_th.blank? rescue nil
      date_th = "<th>&nbsp;</th>" + "<th>#{dates}</th>" if date_th.blank? rescue nil
    }
    return date_th
  end

  def detail_lab_results_html(detail_lab_results)
    available_dates = self. available_test_dates(detail_lab_results,true) 
    patient_name = self.name

    html_tag_to_display = ""
    
    detail_lab_results.sort.each do |name,lab_result |
      test_name = name.gsub("_"," ")
      results = lab_result.split(":").enum_slice(2).map
      results.delete_if{|x|x[0]=="01-Jan-1900"}
      results_to_be_passed_string = ""
      results.each{|y|y.each{|x| if !results_to_be_passed_string.blank? then results_to_be_passed_string+=":" + x else results_to_be_passed_string+=x end}}
      results_to_be_passed_string = lab_result if results_to_be_passed_string.blank?
      results = lab_result.split(":").enum_slice(2).map
      test_value = nil
      html_tag = Array.new()
      available_dates.each{|d| 
        html_tag << "<td>&nbsp;</td>" 
      }

      results.each{|result|
        date_index = available_dates.index(result.first.to_s) 
        test_value = result.last.to_s
        html_tag[date_index] = "<td>#{test_value}</td>" 
      }

      html_tag[0] = "<td class='test_name_td'><input class='test_name' type=\"button\" onmousedown=\"document.location='/patient/detail_lab_results_graph?id=#{results_to_be_passed_string}&name=#{name}&pat_name=#{patient_name}';\" value=\"#{test_name}\"/></td>" + html_tag[0]
      html_tag_to_display+= "<tr>#{html_tag.to_s}</tr>" unless  html_tag[0].blank?
    end
    return html_tag_to_display
  end

  def last_art_visit_ecounter_by_given_date(visit_date)
    date = visit_date.to_s.to_time
    encounter_types_id = EncounterType.find_by_name("ART Visit").id
    Encounter.find(:first,
      :conditions=>["patient_id=? and encounter_type=? and encounter_datetime < ?",
      self.id,encounter_types_id,date],:order=> "encounter_datetime desc") rescue nil
  end

  def drugs_given_last_time(date=Date.today)
    pills_given=self.drug_orders_for_date(date)
    drug_name_and_total_quantity = Hash.new(0)
    pills_given.collect{|dor|
      next if dor.drug.name.to_s =="Insecticide Treated Net" || dor.drug.name.to_s =="Cotrimoxazole 480"
      drug_name_and_total_quantity[dor.drug]+= dor.quantity
    }.compact

    drug_name_and_total_quantity
  end

  def expected_amount_remaining(drug,visit_date=Date.today)
    return if drug.blank?
    previous_visit_date = self.last_art_visit_ecounter_by_given_date(visit_date).encounter_datetime.to_s.to_date rescue nil
    puts previous_visit_date.to_s
    return if previous_visit_date.nil?
    drugs_dispensed_last_time = self.drugs_given_last_time(previous_visit_date)

    return "Drug not given that visit" unless drugs_dispensed_last_time[drug]
    
    if self.previous_art_drug_orders(visit_date).blank?
      self.art_amount_remaining_if_adherent(visit_date)[drug]
    else  
      self.art_amount_remaining_if_adherent(visit_date,false,previous_visit_date)[drug]
    end  
  end
  
  def doses_unaccounted_for_and_doses_missed(drug_obj,date=Date.today)
    concept_name = "Whole tablets remaining and brought to clinic"
    total_amount = Observation.find(:all,:conditions => ["voided = 0 and concept_id=? and patient_id=? and Date(obs_datetime)=?",(Concept.find_by_name(concept_name).id),self.id,date],:order=>"obs.obs_datetime desc") rescue nil 
    drug_actual_amount_remaining = 0
    total_amount.map{|x|x
      next if x.value_drug != drug_obj.id
      drug_actual_amount_remaining+=x.value_numeric
    }
   
    expected_amount = self.expected_amount_remaining(drug_obj,date)
    result = (expected_amount - drug_actual_amount_remaining)
    result.to_s.match(/-/) ?  "Doses unaccounted for:#{result.to_s.gsub("-","")}" : "Doses missed:#{result}"
  end

end
### Original SQL Definition for patient #### 
#   `patient_id` int(11) NOT NULL auto_increment,
#   `gender` varchar(50) NOT NULL default '',
#   `race` varchar(50) default NULL,
#   `birthdate` date default NULL,
#   `birthdate_estimated` tinyint(1) default NULL,
#   `birthplace` varchar(50) default NULL,
#   `tribe` int(11) default NULL,
#   `citizenship` varchar(50) default NULL,
#   `mothers_name` varchar(50) default NULL,
#   `civil_status` int(11) default NULL,
#   `dead` int(1) NOT NULL default '0',
#   `death_date` datetime default NULL,
#   `cause_of_death` varchar(255) default NULL,
#   `health_district` varchar(255) default NULL,
#   `health_center` int(11) default NULL,
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `changed_by` int(11) default NULL,
#   `date_changed` datetime default NULL,
#   `voided` tinyint(1) NOT NULL default '0',
#   `voided_by` int(11) default NULL,
#   `date_voided` datetime default NULL,
#   `void_reason` varchar(255) default NULL,
#   PRIMARY KEY  (`patient_id`),
#   KEY `belongs_to_tribe` (`tribe`),
#   KEY `user_who_created_patient` (`creator`),
#   KEY `user_who_voided_patient` (`voided_by`),
#   KEY `user_who_changed_pat` (`changed_by`),
#   KEY `birthdate` (`birthdate`),
#   CONSTRAINT `belongs_to_tribe` FOREIGN KEY (`tribe`) REFERENCES `tribe` (`tribe_id`),
#   CONSTRAINT `user_who_changed_pat` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_created_patient` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `user_who_voided_patient` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
