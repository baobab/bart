class TableList < OpenMRS
  set_table_name "tblLists"

  def self.person_occupation(occ_id = nil)
    return "Other" if occ_id == 999
    self.find(:first,
      :conditions =>["ListName='Occupation' AND ItemValue=?",occ_id]).ListItem rescue nil
  end

  def self.art_status(art_status_id = nil)
    self.find(:first,
      :conditions =>["ListName='ARTStatus' AND ItemValue=?",art_status_id]).ListItem rescue nil
  end

  def self.location_name(loc_id = nil)
    return "Other" if loc_id == 999
    self.find(:first,
      :conditions =>["ListName='HTC' AND ItemValue=?",loc_id]).ListItem rescue nil
  end

  def self.hiv_related_illness(illness_id = nil)
    concept_name = self.find(:first,
      :conditions =>["ListName LIKE '%HIVRelatedIllness%' AND ItemValue=?",illness_id]).ListItem rescue nil
    Concept.find_by_name(concept_name)  rescue nil
  end

  def self.arv_regimen(regimen_id = nil)
    regimen = self.find(:first,
      :conditions =>["ListName LIKE '%ARTRegimen%' AND ItemValue=?",regimen_id]).ListItem rescue nil
    return nil if regimen.blank?  
    case regimen 
      when "[ADULT]  Triomune 30"
        return [Drug.find(5).concept_id][0]
      when "[ADULT]  Triomune 40"
        return [Drug.find(6).concept_id][0]
      when "[ADULT]  Duovir + Nevirapine"
        return [Drug.find(8).concept_id ,Drug.find(9).concept_id][0]
      when "[ADULT]  Lamivir 30 + Efavirenz"
        return [Drug.find(22).concept_id,Drug.find(7).concept_id][0]
      when "[ADULT]  Duovir + Kaletra + Tenofovir"
        return [Drug.find(8).concept_id,Drug.find(17).concept_id,Drug.find(14).concept_id][0]
      when "[ADULT]  Tenofovir + Nevirapine + Kaletra"
        return [Drug.find(14).concept_id,Drug.find(9).concept_id, Drug.find(17).concept_id][0]
      when "[ADULT]  Tenofovir + Efavirenz  + Kaletra"
        return [Drug.find(14).concept_id,Drug.find(7).concept_id,Drug.find(17).concept_id][0]
      when "[ADULT] Duovir + Kaletra"
        return [Drug.find(8).concept_id,Drug.find(17).concept_id][0]
      when "[CHILD]  ddI + ABC + Kaletra"
        return [Drug.find(49).concept_id,Drug.find(10).concept_id,Drug.find(12).concept_id][0]
      when "[CHILD] Junior Triommune"
        return [Drug.find(56).concept_id][0]
      when "[CHILD] Baby Triommune"
        return [Drug.find(56).concept_id][0]
      when "[CHILD] Lamivir 30 + Efavirenz"
        return [Drug.find(14).concept_id, Drug.find(51).concept_id][0]
      when "[CHILD] Duovir + Nevirapine"
        return [Drug.find(8).concept_id,Drug.find(9).concept_id][0]
    end  
  end

  def self.tb_regimen(regimen_id = nil)
    self.find(:first,
      :conditions =>["ListName LIKE '%TBRegimen%' AND ItemValue=?",regimen_id]).ListItem rescue nil
  end

  def self.tb_outcome(outcome_id = nil)
    concept_name = self.find(:first,
      :conditions =>["ListName LIKE '%TbOutcome%' AND ItemValue=?",outcome_id]).ListItem rescue nil
    concept_name = "Died" if concept_name == "Dead"
    concept_name = "Stop" if concept_name == "Stopped"
    concept_name = "Defaulter" if concept_name == "Defauletd"
    Concept.find_by_name(concept_name)  rescue nil
  end
  
  def self.arv_drug_dispensed(drug_id = nil)
    regimem = self.find(:first,
      :conditions =>["ListName LIKE '%ARTRegimen%' AND ItemValue=?",drug_id]).ListItem rescue nil
    return nil if regimem.blank?
    case regimem
      when "[ADULT]  Triomune 30"
        return [Drug.find(5)]
      when "[ADULT]  Triomune 40"
        return [Drug.find(6)]
      when "[ADULT]  Duovir + Nevirapine"
        return [Drug.find(8),Drug.find(9)]
      when "[ADULT]  Lamivir 30 + Efavirenz"
        return [Drug.find(22),Drug.find(7)]
      when "[ADULT]  Duovir + Kaletra + Tenofovir"
        return [Drug.find(8),Drug.find(17),Drug.find(14)]
      when "[ADULT]  Tenofovir + Nevirapine + Kaletra"
        return [Drug.find(14),Drug.find(9), Drug.find(17)]
      when "[ADULT]  Tenofovir + Efavirenz  + Kaletra"
        return [Drug.find(14),Drug.find(7),Drug.find(17)]
      when "[ADULT] Duovir + Kaletra"
        return [Drug.find(8),Drug.find(17)]
      when "[CHILD]  ddI + ABC + Kaletra"
        return [Drug.find(49),Drug.find(10),Drug.find(12)]
      when "[CHILD] Junior Triommune"
        return [Drug.find(56)]
      when "[CHILD] Baby Triommune"
        return [Drug.find(56)]
      when "[CHILD] Lamivir 30 + Efavirenz"
        return [Drug.find(14), Drug.find(51)]
      when "[CHILD] Duovir + Nevirapine"
        return [Drug.find(8),Drug.find(9)]
    end
  end

  def self.tb_type(tb_id = nil)
    concept_name = self.find(:first,
      :conditions =>["ListName LIKE '%TbType%' AND ItemValue=?",tb_id]).ListItem rescue nil
    concept_name = "Pulmonary tuberculosis (current)" if concept_name == "Pulmonary"
    concept_name = "Extrapulmonary tuberculosis" if concept_name == "ExtraPulmonary"
    Concept.find_by_name(concept_name)  rescue nil
  end
  
  def self.tb_episode_type(tb_id = nil)
    concept_name = self.find(:first,
      :conditions =>["ListName LIKE '%TbEpisodeType%' AND ItemValue=?",tb_id]).ListItem rescue nil
    concept_name = "Failed" if concept_name == "Failure"
    Concept.find_by_name(concept_name)  rescue nil
  end
  
end 
