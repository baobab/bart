class PersonAttribute < OpenMRS
  set_table_name "person_attribute"
  set_primary_key "person_attribute_id"

  belongs_to :patient, :foreign_key => 'person_id'

  def before_save
    super
    self.creator = User.current_user.id
    self.changed_by = User.current_user.id
  end

  ## TODO: make this a person/patient instance method
  def self.create(patient_id, reason, attribute_name = "Reason antiretrovirals started")    
    attribute_type = PersonAttributeType.find_by_name(attribute_name).id rescue nil
    return if reason.blank? or attribute_type.blank? or patient_id.blank?

    # insert or replace
    attribute = PersonAttribute.find(:first, :conditions => ['person_id = ? AND person_attribute_type_id = ?',
                                patient_id, attribute_type])
    attribute = self.new() unless attribute
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
    User.current_user = User.find(1) if User.current_user.blank?
    hiv_staging = EncounterType.find_by_name("HIV Staging").id
=begin
    if Location.current_arv_code == "ZCH"
      unspecified_stage_one = Concept.find_by_name("Unspecified stage 1 condition")
      unspecified_stage_two = Concept.find_by_name("Unspecified stage 2 condition")
      unspecified_stage_three = Concept.find_by_name("Unspecified stage 3 condition")
      unspecified_stage_four = Concept.find_by_name("Unspecified stage 4 condition")
      cd4 = Concept.find_by_name("CD4 Count < 250")
    end  
=end

ActiveRecord::Base.connection.execute <<EOF
DELETE FROM person_attribute;
EOF

    patients = Patient.find(:all,
               :joins => "INNER JOIN encounter e ON e.patient_id=patient.patient_id
                          INNER JOIN obs ON obs.encounter_id=e.encounter_id AND obs.voided=0",
               :conditions => ["e.encounter_type=?",hiv_staging],
               :group => "e.patient_id",:order => "e.encounter_datetime DESC")
    patients.each{|patient|
      art_reason = patient.reason_for_art_eligibility.name rescue nil
      who_stage = patient.who_stage
=begin
      if Location.current_arv_code == "ZCH"
        if art_reason.blank?
          migrated_stage = PatientIdentifier.find(:first,:conditions =>["identifier_type = 24 AND patient_id =?",
            patient.id]).identifier.to_i rescue nil
          if migrated_stage  
            who_stage =  migrated_stage
            case migrated_stage
              when 1
                if patient.encounters.find_by_type_name("Give drugs")
                  art_reason = cd4.name
                else
                  art_reason = unspecified_stage_one.name
                end  
              when 2
                if patient.encounters.find_by_type_name("Give drugs")
                  art_reason = cd4.name
                else
                  art_reason = unspecified_stage_two.name
                end  
              when 3
                art_reason = unspecified_stage_three.name
              when 4
                art_reason = unspecified_stage_four.name
            end
          end 
        end
      end
=end
      self.create(patient.id, art_reason) unless art_reason.blank?
      self.create(patient.id, who_stage, "WHO stage") unless who_stage.blank?
    }
    true
  end

end
