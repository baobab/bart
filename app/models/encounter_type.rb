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
    unless forms.blank?
      form_id = forms.first.id
      staging_interface = GlobalProperty.find_by_property('staging_interface').property_value rescue 'realtime'
      form_id = 56 if form_id == 51 and staging_interface == 'multi_select'
      return "/form/show/" + form_id.to_s
    end  
    return "/drug_order/dispense" if self.name == "Give drugs"
    return "/patient/update_outcome" if self.name == "Update outcome"
  end
end
