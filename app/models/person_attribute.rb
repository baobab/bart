class PersonAttribute < OpenMRS
  set_table_name "person_attribute"
  set_primary_key "person_attribute_id"

  def before_save
    super
    self.creator = User.current_user.id
    self.changed_by = User.current_user.id
  end

  def self.create(patient_id, reason, attribute_name = "Reason antiretrovirals started")    
    attribute_type = PersonAttributeType.find_by_name(attribute_name).id rescue nil
    return if reason.blank? or attribute_type.blank?
    attribute = self.new()
    attribute.person_attribute_type_id = attribute_type
    attribute.person_id = patient_id
    attribute.value = reason
    attribute.save
  end

  def self.art_reason(patient_id)
    attribute_type = PersonAttributeType.find_by_name("Reason antiretrovirals started").id 
    self.find(:first,
              :conditions => ["person_id = ? AND person_attribute_type_id =?",patient_id,attribute_type],
              :order => "date_created DESC").value rescue nil
  end

  def self.who_stage(patient_id)
    attribute_type = PersonAttributeType.find_by_name("WHO stage").id 
    self.find(:first,
              :conditions => ["person_id = ? AND person_attribute_type_id =?",patient_id,attribute_type],
              :order => "date_created DESC").value rescue nil
  end

  def self.reset
    hiv_staging = EncounterType.find_by_name("HIV Staging").id

    patients = Patient.find(:all,
               :joins => "INNER JOIN encounter e ON e.patient_id=patient.patient_id
                          INNER JOIN obs ON obs.encounter_id=e.encounter_id AND obs.voided=0",
               :conditions => ["e.encounter_type=?",hiv_staging],
               :group => "e.patient_id",:order => "e.encounter_datetime DESC")
    patients.each{|patient|
      art_reason = patient.reason_for_art_eligibility.name rescue nil
      who_stage = patient.who_stage
      self.create(patient.id, art_reason) unless art_reason.blank?
      self.create(patient.id, who_stage, "WHO stage") unless who_stage.blank?
    }
    true
  end

end
