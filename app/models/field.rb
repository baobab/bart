class Field < OpenMRS
  set_table_name "field"
  set_primary_key "field_id"
  cache_on "name"
  has_many :form_fields, :foreign_key => :field_id, :dependent => :delete_all
  has_many :forms, :through => :form_fields
  has_many :field_answers, :foreign_key => :field_id
  belongs_to :concept, :foreign_key => :concept_id
  belongs_to :user, :foreign_key => :user_id
  belongs_to :type, :class_name=> "FieldType", :foreign_key => :field_type
end