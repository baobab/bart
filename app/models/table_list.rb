class TableList < OpenMRS
  set_table_name "tbllists"

  def self.person_occupation(occ_id = nil)
    return "Other" if occ_id == 999
    self.find(:first,
      :conditions =>["ListName='Occupation' AND ItemValue=?",occ_id]).ListItem rescue nil
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

end 
