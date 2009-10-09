class EncounterType < OpenMRS
  set_table_name "encounter_type"
  set_primary_key "encounter_type_id"
  set_fixture_name "name"
  
  cache_on "name"
  
  has_many :forms, :foreign_key => :encounter_type
  has_many :encounters, :foreign_key => :encounter_type
  belongs_to :user, :foreign_key => :user_id
  
  def url
    forms = self.forms
    form_id = forms.first.id
    if forms.first.id == 51
      form_id = 56 if GlobalProperty.find_by_property('staging_interface').property_value == 'multi_select' rescue 51
    end
    return "/form/show/" + form_id.to_s unless forms.blank?
    return "/drug_order/dispense" if self.name == "Give drugs"
    return "/patient/update_outcome" if self.name == "Update outcome"
  end
end
