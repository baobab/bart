class Form < OpenMRS
  set_table_name "form"
  set_primary_key "form_id"
  set_fixture_name "name"

  has_many :form_fields, :foreign_key => :form_id, :dependent => :delete_all
  has_many :fields, :through => :form_fields
  has_many :encounters, :foreign_key => :form_id
  belongs_to :type_of_encounter, :class_name => "EncounterType",  :foreign_key => :encounter_type
  belongs_to :user, :foreign_key => :user_id
end

