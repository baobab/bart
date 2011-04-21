class Clinic

  attr_accessor :diagnosis, :secondary_diagnosis, :drug_given , :refered_to, :ht, :wt, :bmi, :outcome, :adherence, :tb_status, :side_effects


  def self.visits(patient_obj)
    visits = {}

    ['Outpatient diagnosis','Referred'].each do | encounter_type |
      encounters = Encounter.find(:all,:conditions => ["patient_id = ? AND encounter_type = ?",
                                  patient_obj.id,EncounterType.find_by_name(encounter_type).id])
      next if encounters.blank?
      (encounters).each do | encounter |
        visit_date = encounter.encounter_datetime.to_date
        ( encounter.observations || [] ).each do | obs |
          visits[visit_date] = self.new() if visits[visit_date].blank?
          case obs.concept.name
            when "Primary diagnosis"
              visits[visit_date].diagnosis = Concept.find(obs.value_coded).name
            when "Secondary diagnosis"
              visits[visit_date].secondary_diagnosis = [] if visits[visit_date].secondary_diagnosis.blank? 
              visits[visit_date].secondary_diagnosis << Concept.find(obs.value_coded).name
            when "Drugs given"
              visits[visit_date].drug_given = [] if visits[visit_date].drug_given.blank?
              visits[visit_date].drug_given << Drug.find(obs.value_drug).name
            else
              visits[visit_date].refered_to = Location.find(obs.value_numeric).name
          end
        end
      end
    end
    
   ( MastercardVisit.visits(patient_obj) || [] ).each do | date , visit |
     visits[date] = self.new() if visits[date].blank?
     visits[date].ht = visit.height
     visits[date].wt = visit.weight
     visits[date].bmi = visit.bmi
     visits[date].outcome = visit.outcome
     visits[date].adherence = visit.adherence
     visits[date].tb_status = visit.tb_status
     visits[date].side_effects = visit.s_eff
     if visits[date].drug_given.blank? and not visit.gave.blank?
      gave = []
      (visit.gave || []).each do | name |
        gave << name 
      end
      visits[date].drug_given = gave
     elsif not visits[date].drug_given.blank? and not visit.gave.blank?
      (visit.gave || []).each do | name |
        visits[date].drug_given << name 
     end
     visits[date].outcome = visit.outcome
     visits[date].bmi = visit.bmi
    end
   end


   visits
  end

end
