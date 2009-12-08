class OutPatientVisit
  attr_accessor :patient_present, :primary_diagnosis, :secondary_diagnosis, :referal_destination, :treatment

  def self.visits(patient_obj)
    patient_visits = {}
    concept_names = []
    concept_names << 'Patient present'
    concept_names << 'Secondary diagnosis'
    concept_names << 'Referred to destination'
    concept_names << 'Primary diagnosis'
    concept_names << 'Drugs given'
    
    concept_names.each{|concept_name|
      concept_id = Concept.find_by_name(concept_name).id
      patient_observations = Observation.find(:all,
                                              :conditions => ["voided = 0 and concept_id=? and patient_id=?",
                                              concept_id,patient_obj.patient_id],
                                              :order=>"obs.obs_datetime desc")

      patient_observations.each{|obs|

        next if obs.blank? or obs.encounter.blank?
        next unless obs.encounter.name == "General Reception" or obs.encounter.name == "Outpatient diagnosis" or obs.encounter.name == "Referred"
        puts obs.encounter.name

        visit_date = obs.obs_datetime.to_date
        patient_visits[visit_date] = self.new() if patient_visits[visit_date].blank?
        case concept_name
          when "Patient present"
            patient_visits[visit_date].patient_present = Concept.find(obs.value_coded).name rescue "No"
          when "Secondary diagnosis"
            secondary_diagnosis = Concept.find(obs.value_coded).name rescue nil
            next if secondary_diagnosis == "Not applicable"
            if patient_visits[visit_date].secondary_diagnosis.blank?
              patient_visits[visit_date].secondary_diagnosis = secondary_diagnosis
            else
              patient_visits[visit_date].secondary_diagnosis+= "<br/>#{secondary_diagnosis}"
            end  
          when "Primary diagnosis"
            patient_visits[visit_date].primary_diagnosis = Concept.find(obs.value_coded).name rescue nil
          when "Referred to destination"
            patient_visits[visit_date].referal_destination = Location.find(obs.value_numeric).name rescue "No"
          when "Drugs given"
            treatment = obs.value_text
            treatment = Drug.find(obs.value_drg).name rescue nil if treatment.blank?
            treatment = Concept.find(obs.value_numeric).name if treatment.blank?
            if patient_visits[visit_date].treatment.blank?
              patient_visits[visit_date].treatment= treatment 
            else  
              patient_visits[visit_date].treatment+= "<br/>#{treatment}" 
            end
        end
      }
    }
    patient_visits
  end

end
