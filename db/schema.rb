# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20080804092558) do

  create_table "complex_obs", :primary_key => "obs_id", :force => true do |t|
    t.integer "mime_type_id",  :limit => 11,         :default => 0, :null => false
    t.text    "urn"
    t.text    "complex_value", :limit => 2147483647
  end

  add_index "complex_obs", ["mime_type_id"], :name => "mime_type_of_content"

  create_table "concept", :primary_key => "concept_id", :force => true do |t|
    t.boolean  "retired",                      :default => false, :null => false
    t.string   "name",                         :default => "",    :null => false
    t.string   "short_name"
    t.text     "description"
    t.text     "form_text"
    t.integer  "datatype_id",    :limit => 11, :default => 0,     :null => false
    t.integer  "class_id",       :limit => 11, :default => 0,     :null => false
    t.boolean  "is_set",                       :default => false, :null => false
    t.string   "icd10"
    t.string   "loinc"
    t.integer  "creator",        :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                    :null => false
    t.integer  "default_charge", :limit => 11
    t.string   "version",        :limit => 50
    t.integer  "changed_by",     :limit => 11
    t.datetime "date_changed"
    t.string   "form_location",  :limit => 50
    t.string   "units",          :limit => 50
    t.integer  "view_count",     :limit => 11
  end

  add_index "concept", ["class_id"], :name => "concept_classes"
  add_index "concept", ["creator"], :name => "concept_creator"
  add_index "concept", ["datatype_id"], :name => "concept_datatypes"
  add_index "concept", ["changed_by"], :name => "user_who_changed_concept"

  create_table "concept_answer", :primary_key => "concept_answer_id", :force => true do |t|
    t.integer  "concept_id",     :limit => 11, :default => 0, :null => false
    t.integer  "answer_concept", :limit => 11
    t.integer  "answer_drug",    :limit => 11
    t.integer  "creator",        :limit => 11, :default => 0, :null => false
    t.datetime "date_created",                                :null => false
  end

  add_index "concept_answer", ["creator"], :name => "answer_creator"
  add_index "concept_answer", ["answer_concept"], :name => "answer"
  add_index "concept_answer", ["concept_id"], :name => "answers_for_concept"

  create_table "concept_class", :primary_key => "concept_class_id", :force => true do |t|
    t.string   "name",                       :default => "", :null => false
    t.string   "description",                :default => "", :null => false
    t.integer  "creator",      :limit => 11, :default => 0,  :null => false
    t.datetime "date_created",                               :null => false
  end

  add_index "concept_class", ["creator"], :name => "concept_class_creator"

  create_table "concept_datatype", :primary_key => "concept_datatype_id", :force => true do |t|
    t.string   "name",                           :default => "", :null => false
    t.string   "hl7_abbreviation", :limit => 3
    t.string   "description",                    :default => "", :null => false
    t.integer  "creator",          :limit => 11, :default => 0,  :null => false
    t.datetime "date_created",                                   :null => false
  end

  add_index "concept_datatype", ["creator"], :name => "concept_datatype_creator"

  create_table "concept_map", :primary_key => "concept_map_id", :force => true do |t|
    t.integer  "source",       :limit => 11
    t.integer  "source_id",    :limit => 11
    t.string   "comment"
    t.integer  "creator",      :limit => 11, :default => 0, :null => false
    t.datetime "date_created",                              :null => false
  end

  add_index "concept_map", ["source"], :name => "map_source"
  add_index "concept_map", ["creator"], :name => "map_creator"

  create_table "concept_name", :id => false, :force => true do |t|
    t.integer  "concept_id",   :limit => 11, :default => 0,  :null => false
    t.string   "name",                       :default => "", :null => false
    t.string   "short_name"
    t.text     "description",                                :null => false
    t.string   "locale",       :limit => 50, :default => "", :null => false
    t.integer  "creator",      :limit => 11, :default => 0,  :null => false
    t.datetime "date_created",                               :null => false
  end

  add_index "concept_name", ["creator"], :name => "user_who_created_name"

  create_table "concept_numeric", :primary_key => "concept_id", :force => true do |t|
    t.float   "hi_absolute"
    t.float   "hi_critical"
    t.float   "hi_normal"
    t.float   "low_absolute"
    t.float   "low_critical"
    t.float   "low_normal"
    t.string  "units",        :limit => 50
    t.boolean "precise",                    :default => false, :null => false
  end

  create_table "concept_proposal", :primary_key => "concept_proposal_id", :force => true do |t|
    t.integer  "concept_id",     :limit => 11
    t.integer  "encounter_id",   :limit => 11
    t.string   "original_text",                :default => "",         :null => false
    t.string   "final_text"
    t.integer  "obs_id",         :limit => 11
    t.integer  "obs_concept_id", :limit => 11
    t.string   "state",          :limit => 32, :default => "UNMAPPED", :null => false
    t.string   "comments"
    t.integer  "creator",        :limit => 11, :default => 0,          :null => false
    t.datetime "date_created",                                         :null => false
    t.integer  "changed_by",     :limit => 11
    t.datetime "date_changed"
  end

  add_index "concept_proposal", ["encounter_id"], :name => "encounter_for_proposal"
  add_index "concept_proposal", ["concept_id"], :name => "concept_for_proposal"
  add_index "concept_proposal", ["creator"], :name => "user_who_created_proposal"
  add_index "concept_proposal", ["changed_by"], :name => "user_who_changed_proposal"
  add_index "concept_proposal", ["obs_id"], :name => "proposal_obs_id"
  add_index "concept_proposal", ["obs_concept_id"], :name => "proposal_obs_concept_id"

  create_table "concept_set", :id => false, :force => true do |t|
    t.integer  "concept_id",   :limit => 11, :default => 0, :null => false
    t.integer  "concept_set",  :limit => 11, :default => 0, :null => false
    t.float    "sort_weight"
    t.integer  "creator",      :limit => 11, :default => 0, :null => false
    t.datetime "date_created",                              :null => false
  end

  add_index "concept_set", ["concept_set"], :name => "has_a"
  add_index "concept_set", ["creator"], :name => "user_who_created"

  create_table "concept_set_derived", :id => false, :force => true do |t|
    t.integer "concept_id",  :limit => 11, :default => 0, :null => false
    t.integer "concept_set", :limit => 11, :default => 0, :null => false
    t.float   "sort_weight"
  end

  create_table "concept_source", :primary_key => "concept_source_id", :force => true do |t|
    t.string   "name",         :limit => 50, :default => "", :null => false
    t.text     "description",                                :null => false
    t.string   "hl7_code",     :limit => 50, :default => "", :null => false
    t.integer  "creator",      :limit => 11, :default => 0,  :null => false
    t.datetime "date_created",                               :null => false
    t.integer  "voided",       :limit => 4
    t.integer  "voided_by",    :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "concept_source", ["creator"], :name => "concept_source_creator"
  add_index "concept_source", ["voided_by"], :name => "user_who_voided_concept_source"

  create_table "concept_state_conversion", :primary_key => "concept_state_conversion_id", :force => true do |t|
    t.integer "concept_id",                :limit => 11, :default => 0
    t.integer "program_workflow_id",       :limit => 11, :default => 0
    t.integer "program_workflow_state_id", :limit => 11, :default => 0
  end

  add_index "concept_state_conversion", ["program_workflow_id", "concept_id"], :name => "unique_workflow_concept_in_conversion", :unique => true
  add_index "concept_state_conversion", ["concept_id"], :name => "triggering_concept"
  add_index "concept_state_conversion", ["program_workflow_id"], :name => "affected_workflow"
  add_index "concept_state_conversion", ["program_workflow_state_id"], :name => "resulting_state"

  create_table "concept_synonym", :id => false, :force => true do |t|
    t.integer  "concept_id",   :limit => 11, :default => 0,  :null => false
    t.string   "synonym",                    :default => "", :null => false
    t.string   "locale"
    t.integer  "creator",      :limit => 11, :default => 0,  :null => false
    t.datetime "date_created",                               :null => false
  end

  add_index "concept_synonym", ["concept_id"], :name => "synonym_for"
  add_index "concept_synonym", ["creator"], :name => "synonym_creator"

  create_table "concept_word", :id => false, :force => true do |t|
    t.integer "concept_id", :limit => 11, :default => 0,  :null => false
    t.string  "word",       :limit => 50, :default => "", :null => false
    t.string  "synonym",                  :default => "", :null => false
    t.string  "locale",     :limit => 20, :default => "", :null => false
  end

  create_table "drug", :primary_key => "drug_id", :force => true do |t|
    t.integer  "concept_id",      :limit => 11,         :default => 0,     :null => false
    t.string   "name",            :limit => 50
    t.boolean  "combination",                           :default => false, :null => false
    t.float    "daily_mg_per_kg"
    t.string   "dosage_form"
    t.float    "dose_strength"
    t.text     "inn",             :limit => 2147483647
    t.float    "maximum_dose"
    t.float    "minimum_dose"
    t.string   "route"
    t.integer  "shelf_life",      :limit => 11
    t.integer  "therapy_class",   :limit => 11
    t.string   "units",           :limit => 50
    t.integer  "creator",         :limit => 11,         :default => 0,     :null => false
    t.datetime "date_created",                                             :null => false
  end

  add_index "drug", ["creator"], :name => "drug_creator"
  add_index "drug", ["concept_id"], :name => "primary_drug_concept"

  create_table "drug_barcodes", :force => true do |t|
    t.integer "drug_id",  :limit => 11, :default => 0,  :null => false
    t.string  "barcode",  :limit => 16, :default => "", :null => false
    t.integer "quantity", :limit => 11, :default => 0
  end

  create_table "drug_ingredient", :id => false, :force => true do |t|
    t.integer "concept_id",    :limit => 11, :default => 0, :null => false
    t.integer "ingredient_id", :limit => 11, :default => 0, :null => false
  end

  add_index "drug_ingredient", ["concept_id"], :name => "combination_drug"

  create_table "drug_order", :primary_key => "drug_order_id", :force => true do |t|
    t.integer "order_id",          :limit => 11, :default => 0,     :null => false
    t.integer "drug_inventory_id", :limit => 11, :default => 0
    t.integer "dose",              :limit => 11
    t.string  "units"
    t.string  "frequency"
    t.boolean "prn",                             :default => false, :null => false
    t.boolean "complex",                         :default => false, :null => false
    t.integer "quantity",          :limit => 11
  end

  add_index "drug_order", ["drug_inventory_id"], :name => "inventory_item"
  add_index "drug_order", ["order_id"], :name => "extends_order"

  create_table "drug_order_delete", :id => false, :force => true do |t|
    t.integer "drug_order_id", :limit => 11
  end

  create_table "encounter", :primary_key => "encounter_id", :force => true do |t|
    t.integer  "encounter_type",     :limit => 11
    t.integer  "patient_id",         :limit => 11, :default => 0, :null => false
    t.integer  "provider_id",        :limit => 11, :default => 0, :null => false
    t.integer  "location_id",        :limit => 11, :default => 0, :null => false
    t.integer  "form_id",            :limit => 11
    t.datetime "encounter_datetime",                              :null => false
    t.integer  "creator",            :limit => 11, :default => 0, :null => false
    t.datetime "date_created",                                    :null => false
  end

  add_index "encounter", ["location_id"], :name => "encounter_location"
  add_index "encounter", ["patient_id"], :name => "encounter_patient"
  add_index "encounter", ["provider_id"], :name => "encounter_provider"
  add_index "encounter", ["encounter_type"], :name => "encounter_type_id"
  add_index "encounter", ["creator"], :name => "encounter_creator"
  add_index "encounter", ["form_id"], :name => "encounter_form"
  add_index "encounter", ["encounter_id"], :name => "ordered_encounters"

  create_table "encounter_type", :primary_key => "encounter_type_id", :force => true do |t|
    t.string   "name",         :limit => 50, :default => "", :null => false
    t.string   "description",  :limit => 50, :default => "", :null => false
    t.integer  "creator",      :limit => 11, :default => 0,  :null => false
    t.datetime "date_created",                               :null => false
  end

  add_index "encounter_type", ["creator"], :name => "user_who_created_type"

  create_table "field", :primary_key => "field_id", :force => true do |t|
    t.string   "name",                          :default => "",    :null => false
    t.text     "description"
    t.integer  "field_type",      :limit => 11
    t.integer  "concept_id",      :limit => 11
    t.string   "table_name",      :limit => 50
    t.string   "attribute_name",  :limit => 50
    t.text     "default_value"
    t.boolean  "select_multiple",               :default => false, :null => false
    t.integer  "creator",         :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                     :null => false
    t.integer  "changed_by",      :limit => 11
    t.datetime "date_changed"
  end

  add_index "field", ["concept_id"], :name => "concept_for_field"
  add_index "field", ["changed_by"], :name => "user_who_changed_field"
  add_index "field", ["creator"], :name => "user_who_created_field"
  add_index "field", ["field_type"], :name => "type_of_field"

  create_table "field_answer", :id => false, :force => true do |t|
    t.integer  "field_id",     :limit => 11, :default => 0, :null => false
    t.integer  "answer_id",    :limit => 11, :default => 0, :null => false
    t.integer  "creator",      :limit => 11, :default => 0, :null => false
    t.datetime "date_created",                              :null => false
  end

  add_index "field_answer", ["field_id"], :name => "answers_for_field"
  add_index "field_answer", ["answer_id"], :name => "field_answer_concept"
  add_index "field_answer", ["creator"], :name => "user_who_created_field_answer"

  create_table "field_type", :primary_key => "field_type_id", :force => true do |t|
    t.string   "name",         :limit => 50
    t.text     "description",  :limit => 2147483647
    t.boolean  "is_set",                             :default => false, :null => false
    t.integer  "creator",      :limit => 11,         :default => 0,     :null => false
    t.datetime "date_created",                                          :null => false
  end

  add_index "field_type", ["creator"], :name => "user_who_created_field_type"

  create_table "field_types", :force => true do |t|
    t.string   "name",         :limit => 50
    t.text     "description",  :limit => 2147483647
    t.boolean  "is_set"
    t.integer  "creator",      :limit => 11
    t.datetime "date_created"
  end

  create_table "fieldids", :id => false, :force => true do |t|
    t.string  "fieldid",  :limit => 100
    t.integer "fieldnum", :limit => 11
  end

  create_table "fields", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "field_type",      :limit => 11
    t.integer  "concept_id",      :limit => 11
    t.string   "table_name",      :limit => 50
    t.string   "attribute_name",  :limit => 50
    t.text     "default_value"
    t.boolean  "select_multiple"
    t.integer  "creator",         :limit => 11
    t.datetime "date_created"
    t.integer  "changed_by",      :limit => 11
    t.datetime "date_changed"
  end

  create_table "form", :primary_key => "form_id", :force => true do |t|
    t.string   "name",                                          :default => "",    :null => false
    t.string   "version",                   :limit => 50,       :default => "",    :null => false
    t.integer  "build",                     :limit => 11
    t.integer  "published",                 :limit => 4,        :default => 0,     :null => false
    t.text     "description"
    t.integer  "encounter_type",            :limit => 11
    t.string   "schema_namespace"
    t.text     "template",                  :limit => 16777215
    t.string   "infopath_solution_version", :limit => 50
    t.string   "uri"
    t.text     "xslt",                      :limit => 16777215
    t.integer  "creator",                   :limit => 11,       :default => 0,     :null => false
    t.datetime "date_created",                                                     :null => false
    t.integer  "changed_by",                :limit => 11
    t.datetime "date_changed"
    t.boolean  "retired",                                       :default => false, :null => false
    t.integer  "retired_by",                :limit => 11
    t.datetime "date_retired"
    t.string   "retired_reason"
  end

  add_index "form", ["creator"], :name => "user_who_created_form"
  add_index "form", ["changed_by"], :name => "user_who_last_changed_form"
  add_index "form", ["retired_by"], :name => "user_who_retired_form"
  add_index "form", ["encounter_type"], :name => "encounter_type"

  create_table "form_field", :primary_key => "form_field_id", :force => true do |t|
    t.integer  "form_id",           :limit => 11, :default => 0, :null => false
    t.integer  "field_id",          :limit => 11, :default => 0, :null => false
    t.integer  "field_number",      :limit => 11
    t.string   "field_part",        :limit => 5
    t.integer  "page_number",       :limit => 11
    t.integer  "parent_form_field", :limit => 11
    t.integer  "min_occurs",        :limit => 11
    t.integer  "max_occurs",        :limit => 11
    t.boolean  "required"
    t.integer  "changed_by",        :limit => 11
    t.datetime "date_changed"
    t.integer  "creator",           :limit => 11, :default => 0, :null => false
    t.datetime "date_created",                                   :null => false
  end

  add_index "form_field", ["changed_by"], :name => "user_who_last_changed_form_field"
  add_index "form_field", ["field_id"], :name => "field_within_form"
  add_index "form_field", ["form_id"], :name => "form_containing_field"
  add_index "form_field", ["parent_form_field"], :name => "form_field_hierarchy"
  add_index "form_field", ["creator"], :name => "user_who_created_form_field"

  create_table "form_fields", :force => true do |t|
    t.integer  "form_id",           :limit => 11
    t.integer  "field_id",          :limit => 11
    t.integer  "field_number",      :limit => 11
    t.string   "field_part",        :limit => 5
    t.integer  "page_number",       :limit => 11
    t.integer  "parent_form_field", :limit => 11
    t.integer  "min_occurs",        :limit => 11
    t.integer  "max_occurs",        :limit => 11
    t.boolean  "required"
    t.integer  "changed_by",        :limit => 11
    t.datetime "date_changed"
    t.integer  "creator",           :limit => 11
    t.datetime "date_created"
  end

  create_table "formentry_archive", :primary_key => "formentry_archive_id", :force => true do |t|
    t.text     "form_data",    :limit => 16777215,                :null => false
    t.datetime "date_created",                                    :null => false
    t.integer  "creator",      :limit => 11,       :default => 0, :null => false
  end

  add_index "formentry_archive", ["creator"], :name => "User who created formentry_archive"

  create_table "formentry_error", :primary_key => "formentry_error_id", :force => true do |t|
    t.text     "form_data",     :limit => 16777215,                 :null => false
    t.string   "error",                             :default => "", :null => false
    t.text     "error_details"
    t.integer  "creator",       :limit => 11,       :default => 0,  :null => false
    t.datetime "date_created",                                      :null => false
  end

  add_index "formentry_error", ["creator"], :name => "User who created formentry_error"

  create_table "formentry_queue", :primary_key => "formentry_queue_id", :force => true do |t|
    t.text     "form_data",      :limit => 16777215,                :null => false
    t.integer  "status",         :limit => 11,       :default => 0, :null => false
    t.datetime "date_processed"
    t.string   "error_msg"
    t.integer  "creator",        :limit => 11,       :default => 0, :null => false
    t.datetime "date_created",                                      :null => false
  end

  create_table "forms", :force => true do |t|
    t.string   "name"
    t.string   "version",                   :limit => 50
    t.integer  "build",                     :limit => 11
    t.integer  "published",                 :limit => 4
    t.text     "description"
    t.integer  "encounter_type",            :limit => 11
    t.string   "schema_namespace"
    t.text     "template",                  :limit => 16777215
    t.string   "infopath_solution_version", :limit => 50
    t.string   "uri"
    t.text     "xslt",                      :limit => 16777215
    t.integer  "creator",                   :limit => 11
    t.datetime "date_created"
    t.integer  "changed_by",                :limit => 11
    t.datetime "date_changed"
    t.boolean  "retired"
    t.integer  "retired_by",                :limit => 11
    t.datetime "date_retired"
    t.string   "retired_reason"
  end

  create_table "global_property", :force => true do |t|
    t.string "property"
    t.string "property_value"
  end

  create_table "heart_beat", :force => true do |t|
    t.string   "ip",         :limit => 20
    t.string   "property",   :limit => 200
    t.string   "value",      :limit => 200
    t.datetime "time_stamp"
    t.string   "username",   :limit => 10
    t.string   "url",        :limit => 100
  end

  create_table "hl7_in_archive", :primary_key => "hl7_in_archive_id", :force => true do |t|
    t.integer  "hl7_source",     :limit => 11,       :default => 0, :null => false
    t.string   "hl7_source_key"
    t.text     "hl7_data",       :limit => 16777215,                :null => false
    t.datetime "date_created",                                      :null => false
  end

  create_table "hl7_in_error", :primary_key => "hl7_in_error_id", :force => true do |t|
    t.integer  "hl7_source",     :limit => 11,       :default => 0,  :null => false
    t.text     "hl7_source_key"
    t.text     "hl7_data",       :limit => 16777215,                 :null => false
    t.string   "error",                              :default => "", :null => false
    t.text     "error_details"
    t.datetime "date_created",                                       :null => false
  end

  create_table "hl7_in_queue", :primary_key => "hl7_in_queue_id", :force => true do |t|
    t.integer  "hl7_source",     :limit => 11,       :default => 0, :null => false
    t.text     "hl7_source_key"
    t.text     "hl7_data",       :limit => 16777215,                :null => false
    t.integer  "state",          :limit => 11,       :default => 0, :null => false
    t.datetime "date_processed"
    t.text     "error_msg"
    t.datetime "date_created"
  end

  add_index "hl7_in_queue", ["hl7_source"], :name => "hl7_source"

  create_table "hl7_source", :primary_key => "hl7_source_id", :force => true do |t|
    t.string   "name",                        :default => "", :null => false
    t.text     "description",  :limit => 255
    t.integer  "creator",      :limit => 11,  :default => 0,  :null => false
    t.datetime "date_created",                                :null => false
  end

  add_index "hl7_source", ["creator"], :name => "creator"

  create_table "location", :primary_key => "location_id", :force => true do |t|
    t.string   "name",                             :default => "", :null => false
    t.string   "description"
    t.string   "address1",           :limit => 50
    t.string   "address2",           :limit => 50
    t.string   "city_village",       :limit => 50
    t.string   "state_province",     :limit => 50
    t.string   "postal_code",        :limit => 50
    t.string   "country",            :limit => 50
    t.string   "latitude",           :limit => 50
    t.string   "longitude",          :limit => 50
    t.integer  "parent_location_id", :limit => 11
    t.integer  "creator",            :limit => 11, :default => 0,  :null => false
    t.datetime "date_created",                                     :null => false
  end

  add_index "location", ["creator"], :name => "user_who_created_location"

  create_table "mastercards", :force => true do |t|
    t.string  "arvnumber",         :limit => 50,  :null => false
    t.string  "fieldid",           :limit => 100, :null => false
    t.string  "fieldvalue",        :limit => 100, :null => false
    t.string  "entry",             :limit => 1,   :null => false
    t.integer "mastercard_number", :limit => 2
    t.string  "username",          :limit => 20
  end

  create_table "mime_type", :primary_key => "mime_type_id", :force => true do |t|
    t.string "mime_type",   :limit => 75, :default => "", :null => false
    t.text   "description"
  end

  add_index "mime_type", ["mime_type_id"], :name => "mime_type_id"

  create_table "note", :primary_key => "note_id", :force => true do |t|
    t.string   "note_type",    :limit => 50
    t.integer  "patient_id",   :limit => 11
    t.integer  "obs_id",       :limit => 11
    t.integer  "encounter_id", :limit => 11
    t.text     "text",                                      :null => false
    t.integer  "priority",     :limit => 11
    t.integer  "parent",       :limit => 11
    t.integer  "creator",      :limit => 11, :default => 0, :null => false
    t.datetime "date_created",                              :null => false
    t.integer  "changed_by",   :limit => 11
    t.datetime "date_changed"
  end

  add_index "note", ["patient_id"], :name => "patient_note"
  add_index "note", ["obs_id"], :name => "obs_note"
  add_index "note", ["encounter_id"], :name => "encounter_note"
  add_index "note", ["creator"], :name => "user_who_created_note"
  add_index "note", ["changed_by"], :name => "user_who_changed_note"
  add_index "note", ["parent"], :name => "note_hierarchy"

  create_table "notification_alert", :primary_key => "alert_id", :force => true do |t|
    t.string   "text",             :limit => 512,                :null => false
    t.integer  "satisfied_by_any", :limit => 1,   :default => 0, :null => false
    t.integer  "alert_read",       :limit => 1,   :default => 0, :null => false
    t.datetime "date_to_expire"
    t.integer  "creator",          :limit => 11,                 :null => false
    t.datetime "date_created",                                   :null => false
    t.integer  "changed_by",       :limit => 11
    t.datetime "date_changed"
  end

  add_index "notification_alert", ["creator"], :name => "alert_creator"
  add_index "notification_alert", ["changed_by"], :name => "user_who_changed_alert"

  create_table "notification_alert_recipient", :id => false, :force => true do |t|
    t.integer   "alert_id",     :limit => 11,                :null => false
    t.integer   "user_id",      :limit => 11,                :null => false
    t.integer   "alert_read",   :limit => 1,  :default => 0, :null => false
    t.timestamp "date_changed"
  end

  add_index "notification_alert_recipient", ["user_id"], :name => "alert_read_by_user"
  add_index "notification_alert_recipient", ["alert_id"], :name => "id_of_alert"

  create_table "notification_template", :primary_key => "template_id", :force => true do |t|
    t.string  "name",       :limit => 50
    t.text    "template"
    t.string  "subject",    :limit => 100
    t.string  "sender"
    t.string  "recipients", :limit => 512
    t.integer "ordinal",    :limit => 11,  :default => 0
  end

  create_table "obs", :primary_key => "obs_id", :force => true do |t|
    t.integer  "patient_id",       :limit => 11, :default => 0,     :null => false
    t.integer  "concept_id",       :limit => 11, :default => 0,     :null => false
    t.integer  "encounter_id",     :limit => 11
    t.integer  "order_id",         :limit => 11
    t.datetime "obs_datetime",                                      :null => false
    t.integer  "location_id",      :limit => 11, :default => 0,     :null => false
    t.integer  "obs_group_id",     :limit => 11
    t.string   "accession_number"
    t.integer  "value_group_id",   :limit => 11
    t.boolean  "value_boolean"
    t.integer  "value_coded",      :limit => 11
    t.integer  "value_drug",       :limit => 11
    t.datetime "value_datetime"
    t.float    "value_numeric"
    t.string   "value_modifier",   :limit => 2
    t.text     "value_text"
    t.datetime "date_started"
    t.datetime "date_stopped"
    t.string   "comments"
    t.integer  "creator",          :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                      :null => false
    t.boolean  "voided",                         :default => false, :null => false
    t.integer  "voided_by",        :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "obs", ["value_coded"], :name => "answer_concept"
  add_index "obs", ["value_drug"], :name => "answer_concept_drug"
  add_index "obs", ["encounter_id"], :name => "encounter_observations"
  add_index "obs", ["concept_id"], :name => "obs_concept"
  add_index "obs", ["creator"], :name => "obs_enterer"
  add_index "obs", ["location_id"], :name => "obs_location"
  add_index "obs", ["order_id"], :name => "obs_order"
  add_index "obs", ["patient_id"], :name => "patient_obs"
  add_index "obs", ["voided_by"], :name => "user_who_voided_obs"

  create_table "order_type", :primary_key => "order_type_id", :force => true do |t|
    t.string   "name",                       :default => "", :null => false
    t.string   "description",                :default => "", :null => false
    t.integer  "creator",      :limit => 11, :default => 0,  :null => false
    t.datetime "date_created",                               :null => false
  end

  add_index "order_type", ["creator"], :name => "type_created_by"

  create_table "orders", :primary_key => "order_id", :force => true do |t|
    t.integer  "order_type_id",       :limit => 11, :default => 0,     :null => false
    t.integer  "concept_id",          :limit => 11, :default => 0,     :null => false
    t.integer  "orderer",             :limit => 11, :default => 0
    t.integer  "encounter_id",        :limit => 11
    t.text     "instructions"
    t.datetime "start_date"
    t.datetime "auto_expire_date"
    t.boolean  "discontinued",                      :default => false, :null => false
    t.datetime "discontinued_date"
    t.integer  "discontinued_by",     :limit => 11
    t.string   "discontinued_reason"
    t.integer  "creator",             :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                         :null => false
    t.boolean  "voided",                            :default => false, :null => false
    t.integer  "voided_by",           :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "orders", ["creator"], :name => "order_creator"
  add_index "orders", ["orderer"], :name => "orderer_not_drug"
  add_index "orders", ["encounter_id"], :name => "orders_in_encounter"
  add_index "orders", ["order_type_id"], :name => "type_of_order"
  add_index "orders", ["discontinued_by"], :name => "user_who_discontinued_order"
  add_index "orders", ["voided_by"], :name => "user_who_voided_order"

  create_table "orders_drug_order", :id => false, :force => true do |t|
    t.integer  "encounter_id",       :limit => 11
    t.integer  "encounter_type",     :limit => 11
    t.datetime "encounter_datetime"
    t.integer  "drug_inventory_id",  :limit => 11
    t.integer  "quantity",           :limit => 11
    t.integer  "orderer",            :limit => 11
  end

  create_table "paper_mastercards", :force => true do |t|
    t.string  "arvnumber",         :limit => 50,  :null => false
    t.string  "fieldid",           :limit => 100, :null => false
    t.string  "fieldvalue",        :limit => 100, :null => false
    t.string  "entry",             :limit => 1,   :null => false
    t.integer "mastercard_number", :limit => 2
    t.string  "username",          :limit => 20
  end

  create_table "patient", :primary_key => "patient_id", :force => true do |t|
    t.string   "gender",              :limit => 50, :default => "",    :null => false
    t.string   "race",                :limit => 50
    t.date     "birthdate"
    t.boolean  "birthdate_estimated"
    t.string   "birthplace",          :limit => 50
    t.integer  "tribe",               :limit => 11
    t.string   "citizenship",         :limit => 50
    t.string   "mothers_name",        :limit => 50
    t.integer  "civil_status",        :limit => 11
    t.integer  "dead",                :limit => 1,  :default => 0,     :null => false
    t.datetime "death_date"
    t.string   "cause_of_death"
    t.string   "health_district"
    t.integer  "health_center",       :limit => 11
    t.integer  "creator",             :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                         :null => false
    t.integer  "changed_by",          :limit => 11
    t.datetime "date_changed"
    t.boolean  "voided",                            :default => false, :null => false
    t.integer  "voided_by",           :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "patient", ["tribe"], :name => "belongs_to_tribe"
  add_index "patient", ["creator"], :name => "user_who_created_patient"
  add_index "patient", ["voided_by"], :name => "user_who_voided_patient"
  add_index "patient", ["changed_by"], :name => "user_who_changed_pat"
  add_index "patient", ["birthdate"], :name => "birthdate"

  create_table "patient_address", :primary_key => "patient_address_id", :force => true do |t|
    t.integer  "patient_id",     :limit => 11, :default => 0,     :null => false
    t.boolean  "preferred",                    :default => false, :null => false
    t.string   "address1",       :limit => 50
    t.string   "address2",       :limit => 50
    t.string   "city_village",   :limit => 50
    t.string   "state_province", :limit => 50
    t.string   "postal_code",    :limit => 50
    t.string   "country",        :limit => 50
    t.string   "latitude",       :limit => 50
    t.string   "longitude",      :limit => 50
    t.integer  "creator",        :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                    :null => false
    t.boolean  "voided",                       :default => false, :null => false
    t.integer  "voided_by",      :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "patient_address", ["creator"], :name => "patient_address_creator"
  add_index "patient_address", ["patient_id"], :name => "patient_addresses"
  add_index "patient_address", ["voided_by"], :name => "patient_address_void"

  create_table "patient_adherence_dates", :force => true do |t|
    t.integer "patient_id",         :limit => 11, :null => false
    t.integer "drug_id",            :limit => 11, :null => false
    t.date    "visit_date",                       :null => false
    t.date    "drugs_run_out_date",               :null => false
    t.date    "default_date",                     :null => false
  end

  add_index "patient_adherence_dates", ["patient_id", "visit_date", "default_date"], :name => "patient_id_visit_date_default_date"

  create_table "patient_identifier", :id => false, :force => true do |t|
    t.integer  "patient_id",      :limit => 11, :default => 0,     :null => false
    t.string   "identifier",      :limit => 50, :default => "",    :null => false
    t.integer  "identifier_type", :limit => 11, :default => 0,     :null => false
    t.integer  "preferred",       :limit => 4,  :default => 0,     :null => false
    t.integer  "location_id",     :limit => 11, :default => 0,     :null => false
    t.integer  "creator",         :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                     :null => false
    t.boolean  "voided",                        :default => false, :null => false
    t.integer  "voided_by",       :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "patient_identifier", ["identifier_type"], :name => "defines_identifier_type"
  add_index "patient_identifier", ["creator"], :name => "identifier_creator"
  add_index "patient_identifier", ["voided_by"], :name => "identifier_voider"
  add_index "patient_identifier", ["location_id"], :name => "identifier_location"
  add_index "patient_identifier", ["identifier"], :name => "identifier_name"

  create_table "patient_identifier_type", :primary_key => "patient_identifier_type_id", :force => true do |t|
    t.string   "name",         :limit => 50, :default => "",    :null => false
    t.text     "description",                                   :null => false
    t.string   "format",       :limit => 50
    t.boolean  "check_digit",                :default => false, :null => false
    t.integer  "creator",      :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                  :null => false
  end

  add_index "patient_identifier_type", ["creator"], :name => "type_creator"

  create_table "patient_name", :primary_key => "patient_name_id", :force => true do |t|
    t.boolean  "preferred",                        :default => false, :null => false
    t.integer  "patient_id",         :limit => 11, :default => 0,     :null => false
    t.string   "prefix",             :limit => 50
    t.string   "given_name",         :limit => 50
    t.string   "middle_name",        :limit => 50
    t.string   "family_name_prefix", :limit => 50
    t.string   "family_name",        :limit => 50
    t.string   "family_name2",       :limit => 50
    t.string   "family_name_suffix", :limit => 50
    t.string   "degree",             :limit => 50
    t.integer  "creator",            :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                        :null => false
    t.boolean  "voided",                           :default => false, :null => false
    t.integer  "voided_by",          :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
    t.integer  "changed_by",         :limit => 11
    t.datetime "date_changed"
  end

  add_index "patient_name", ["patient_id"], :name => "name_for_patient"
  add_index "patient_name", ["creator"], :name => "user_who_made_name"
  add_index "patient_name", ["voided_by"], :name => "user_who_voided_name"
  add_index "patient_name", ["given_name"], :name => "first_name"
  add_index "patient_name", ["middle_name"], :name => "middle_name"
  add_index "patient_name", ["family_name"], :name => "last_name"

  create_table "patient_prescription_totals", :force => true do |t|
    t.integer "patient_id",        :limit => 11, :null => false
    t.integer "drug_id",           :limit => 11, :null => false
    t.date    "prescription_date",               :null => false
    t.integer "daily_consumption", :limit => 11, :null => false
  end

  add_index "patient_prescription_totals", ["patient_id", "drug_id", "prescription_date"], :name => "patient_id_drug_id_presciption_date"

  create_table "patient_program", :primary_key => "patient_program_id", :force => true do |t|
    t.integer  "patient_id",     :limit => 11, :default => 0,     :null => false
    t.integer  "program_id",     :limit => 11, :default => 0,     :null => false
    t.datetime "date_enrolled"
    t.datetime "date_completed"
    t.integer  "creator",        :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                    :null => false
    t.integer  "changed_by",     :limit => 11
    t.datetime "date_changed"
    t.boolean  "voided",                       :default => false, :null => false
    t.integer  "voided_by",      :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "patient_program", ["patient_id"], :name => "patient_in_program"
  add_index "patient_program", ["program_id"], :name => "program_for_patient"
  add_index "patient_program", ["creator"], :name => "patient_program_creator"
  add_index "patient_program", ["changed_by"], :name => "user_who_changed"
  add_index "patient_program", ["voided_by"], :name => "user_who_voided_patient_program"

  create_table "patient_state", :primary_key => "patient_state_id", :force => true do |t|
    t.integer  "patient_program_id", :limit => 11, :default => 0,     :null => false
    t.integer  "state",              :limit => 11, :default => 0,     :null => false
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "creator",            :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                        :null => false
    t.integer  "changed_by",         :limit => 11
    t.datetime "date_changed"
    t.boolean  "voided",                           :default => false, :null => false
    t.integer  "voided_by",          :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "patient_state", ["state"], :name => "state_for_patient"
  add_index "patient_state", ["patient_program_id"], :name => "patient_program_for_state"
  add_index "patient_state", ["creator"], :name => "patient_state_creator"
  add_index "patient_state", ["changed_by"], :name => "patient_state_changer"
  add_index "patient_state", ["voided_by"], :name => "patient_state_voider"

  create_table "patient_whole_tablets_remaining_and_brought", :force => true do |t|
    t.integer "patient_id",      :limit => 11, :null => false
    t.integer "drug_id",         :limit => 11, :null => false
    t.date    "visit_date",                    :null => false
    t.integer "total_remaining", :limit => 11, :null => false
  end

  add_index "patient_whole_tablets_remaining_and_brought", ["patient_id", "drug_id", "visit_date"], :name => "patient_id_drug_id_presciption_date"

  create_table "person", :primary_key => "person_id", :force => true do |t|
    t.integer "patient_id", :limit => 11
    t.integer "user_id",    :limit => 11
  end

  add_index "person", ["patient_id"], :name => "patients"
  add_index "person", ["user_id"], :name => "users"

  create_table "pih_datas", :force => true do |t|
    t.string  "name",                :limit => 70
    t.string  "year_registered",     :limit => 8
    t.string  "stage",               :limit => 10
    t.string  "date_registered",     :limit => 40
    t.string  "date_started",        :limit => 40
    t.string  "unique_id",           :limit => 10
    t.string  "who_stage",           :limit => 10
    t.string  "reason_for_starting", :limit => 150
    t.integer "age",                 :limit => 11
    t.string  "sex",                 :limit => 10
    t.string  "bmi",                 :limit => 6
    t.string  "cd_4",                :limit => 20
    t.string  "transfer_in",         :limit => 4
    t.string  "transfer_out",        :limit => 4
    t.string  "death",               :limit => 4
    t.string  "stop",                :limit => 4
    t.string  "defaulter",           :limit => 4
    t.string  "side_effects",        :limit => 10
    t.string  "regimen",             :limit => 50
  end

  create_table "prescription_frequencies", :force => true do |t|
    t.string  "frequency",                    :null => false
    t.integer "frequency_days", :limit => 11, :null => false
  end

  add_index "prescription_frequencies", ["frequency"], :name => "frequency_index"

  create_table "prescription_time_periods", :force => true do |t|
    t.string  "time_period",                    :null => false
    t.integer "time_period_days", :limit => 11, :null => false
  end

  add_index "prescription_time_periods", ["time_period"], :name => "time_period_index"

  create_table "privilege", :primary_key => "privilege_id", :force => true do |t|
    t.string "privilege",   :limit => 50,  :default => "", :null => false
    t.string "description", :limit => 250, :default => "", :null => false
  end

  create_table "program", :primary_key => "program_id", :force => true do |t|
    t.integer  "concept_id",   :limit => 11, :default => 0,     :null => false
    t.integer  "creator",      :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                  :null => false
    t.integer  "changed_by",   :limit => 11
    t.datetime "date_changed"
    t.boolean  "voided",                     :default => false, :null => false
    t.integer  "voided_by",    :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "program", ["concept_id"], :name => "program_concept"
  add_index "program", ["creator"], :name => "program_creator"
  add_index "program", ["changed_by"], :name => "user_who_changed_program"
  add_index "program", ["voided_by"], :name => "user_who_voided_program"

  create_table "program_workflow", :primary_key => "program_workflow_id", :force => true do |t|
    t.integer  "program_id",   :limit => 11, :default => 0, :null => false
    t.integer  "concept_id",   :limit => 11, :default => 0, :null => false
    t.integer  "creator",      :limit => 11, :default => 0, :null => false
    t.datetime "date_created",                              :null => false
    t.boolean  "voided"
    t.integer  "voided_by",    :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "program_workflow", ["program_id"], :name => "program_for_workflow"
  add_index "program_workflow", ["concept_id"], :name => "workflow_concept"
  add_index "program_workflow", ["creator"], :name => "workflow_creator"
  add_index "program_workflow", ["voided_by"], :name => "workflow_voided_by"

  create_table "program_workflow_state", :primary_key => "program_workflow_state_id", :force => true do |t|
    t.integer  "program_workflow_id", :limit => 11, :default => 0,     :null => false
    t.integer  "concept_id",          :limit => 11, :default => 0,     :null => false
    t.boolean  "initial",                           :default => false, :null => false
    t.boolean  "terminal",                          :default => false, :null => false
    t.integer  "creator",             :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                         :null => false
    t.boolean  "voided"
    t.integer  "voided_by",           :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "program_workflow_state", ["program_workflow_id"], :name => "workflow_for_state"
  add_index "program_workflow_state", ["concept_id"], :name => "state_concept"
  add_index "program_workflow_state", ["creator"], :name => "state_creator"
  add_index "program_workflow_state", ["voided_by"], :name => "state_voided_by"

  create_table "relationship", :primary_key => "relationship_id", :force => true do |t|
    t.integer  "person_id",    :limit => 11, :default => 0,     :null => false
    t.integer  "relationship", :limit => 11, :default => 0,     :null => false
    t.integer  "relative_id",  :limit => 11, :default => 0,     :null => false
    t.integer  "creator",      :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                  :null => false
    t.boolean  "voided",                     :default => false, :null => false
    t.integer  "voided_by",    :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "relationship", ["person_id"], :name => "related_person"
  add_index "relationship", ["relative_id"], :name => "related_relative"
  add_index "relationship", ["relationship"], :name => "relationship_type"
  add_index "relationship", ["creator"], :name => "relation_creator"
  add_index "relationship", ["voided_by"], :name => "relation_voider"

  create_table "relationship_type", :primary_key => "relationship_type_id", :force => true do |t|
    t.string   "name",         :limit => 50, :default => "", :null => false
    t.string   "description",                :default => "", :null => false
    t.integer  "creator",      :limit => 11, :default => 0,  :null => false
    t.datetime "date_created",                               :null => false
  end

  add_index "relationship_type", ["creator"], :name => "user_who_created_rel"

  create_table "report", :primary_key => "report_id", :force => true do |t|
    t.string   "name",                       :default => "", :null => false
    t.text     "description"
    t.integer  "creator",      :limit => 11, :default => 0,  :null => false
    t.datetime "date_created",                               :null => false
    t.integer  "changed_by",   :limit => 11
    t.datetime "date_changed"
    t.boolean  "voided"
    t.integer  "voided_by",    :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "report", ["creator"], :name => "report_creator"
  add_index "report", ["changed_by"], :name => "user_who_changed_report"
  add_index "report", ["voided_by"], :name => "user_who_voided_report"

  create_table "report_object", :primary_key => "report_object_id", :force => true do |t|
    t.string   "name",                                   :null => false
    t.string   "description",            :limit => 1000
    t.string   "report_object_type",                     :null => false
    t.string   "report_object_sub_type",                 :null => false
    t.text     "xml_data"
    t.integer  "creator",                :limit => 11,   :null => false
    t.datetime "date_created",                           :null => false
    t.integer  "changed_by",             :limit => 11
    t.datetime "date_changed"
    t.boolean  "voided",                                 :null => false
    t.integer  "voided_by",              :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "report_object", ["creator"], :name => "report_object_creator"
  add_index "report_object", ["changed_by"], :name => "user_who_changed_report_object"
  add_index "report_object", ["voided_by"], :name => "user_who_voided_report_object"

  create_table "role", :primary_key => "role_id", :force => true do |t|
    t.string "role",        :limit => 50, :default => "", :null => false
    t.string "description",               :default => "", :null => false
  end

  create_table "role_privilege", :id => false, :force => true do |t|
    t.integer "role_id",      :limit => 11, :null => false
    t.integer "privilege_id", :limit => 11, :null => false
  end

  add_index "role_privilege", ["role_id"], :name => "role_privilege"

  create_table "role_role", :id => false, :force => true do |t|
    t.integer "parent_role_id", :limit => 11, :null => false
    t.integer "child_role_id",  :limit => 11, :null => false
  end

  add_index "role_role", ["child_role_id"], :name => "inherited_role"

  create_table "scheduler_task_config", :primary_key => "task_config_id", :force => true do |t|
    t.string   "name",                                              :null => false
    t.string   "description",        :limit => 1024
    t.text     "schedulable_class"
    t.datetime "start_time",                                        :null => false
    t.string   "start_time_pattern", :limit => 50
    t.integer  "repeat_interval",    :limit => 11,   :default => 0, :null => false
    t.integer  "start_on_startup",   :limit => 1,    :default => 0, :null => false
    t.integer  "started",            :limit => 1,    :default => 0, :null => false
    t.integer  "created_by",         :limit => 11,   :default => 0
    t.datetime "date_created"
    t.integer  "changed_by",         :limit => 11
    t.datetime "date_changed"
  end

  add_index "scheduler_task_config", ["created_by"], :name => "schedule_creator"
  add_index "scheduler_task_config", ["changed_by"], :name => "schedule_changer"

  create_table "scheduler_task_config_property", :id => false, :force => true do |t|
    t.integer "task_config_id", :limit => 11,  :default => 0,  :null => false
    t.string  "property",       :limit => 100, :default => "", :null => false
    t.string  "property_value",                :default => "", :null => false
  end

  create_table "schema_info", :id => false, :force => true do |t|
    t.integer "version", :limit => 11
  end

  create_table "session", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "session", ["session_id"], :name => "sessions_session_id_index"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "tribe", :primary_key => "tribe_id", :force => true do |t|
    t.boolean "retired",               :default => false, :null => false
    t.string  "name",    :limit => 50, :default => "",    :null => false
  end

  create_table "user_property", :id => false, :force => true do |t|
    t.integer "user_id",        :limit => 11,  :default => 0,  :null => false
    t.string  "property",       :limit => 100, :default => "", :null => false
    t.string  "property_value",                :default => "", :null => false
  end

  create_table "user_role", :id => false, :force => true do |t|
    t.integer "user_id", :limit => 11, :default => 0, :null => false
    t.integer "role_id", :limit => 11,                :null => false
  end

  add_index "user_role", ["user_id"], :name => "user_role"

  create_table "users", :primary_key => "user_id", :force => true do |t|
    t.string   "system_id",       :limit => 50, :default => "",    :null => false
    t.string   "username",        :limit => 50
    t.string   "first_name",      :limit => 50
    t.string   "middle_name",     :limit => 50
    t.string   "last_name",       :limit => 50
    t.string   "password",        :limit => 50
    t.string   "salt",            :limit => 50
    t.string   "secret_question"
    t.string   "secret_answer"
    t.integer  "creator",         :limit => 11, :default => 0,     :null => false
    t.datetime "date_created",                                     :null => false
    t.integer  "changed_by",      :limit => 11
    t.datetime "date_changed"
    t.boolean  "voided",                        :default => false, :null => false
    t.integer  "voided_by",       :limit => 11
    t.datetime "date_voided"
    t.string   "void_reason"
  end

  add_index "users", ["creator"], :name => "user_creator"
  add_index "users", ["changed_by"], :name => "user_who_changed_user"
  add_index "users", ["voided_by"], :name => "user_who_voided_user"

  create_table "weight_for_heights", :force => true do |t|
    t.float "supinecm"
    t.float "median_weight_height"
  end

  create_table "weight_height_for_ages", :id => false, :force => true do |t|
    t.integer "age_in_months",        :limit => 6
    t.string  "sex",                  :limit => 12
    t.float   "median_height"
    t.float   "standard_low_height"
    t.float   "standard_high_height"
    t.float   "median_weight"
    t.float   "standard_low_weight"
    t.float   "standard_high_weight"
    t.string  "age_sex",              :limit => 4
  end

  create_view "patient_default_dates", "select `patient_adherence_dates`.`patient_id` AS `patient_id`,`patient_adherence_dates`.`default_date` AS `default_date` from `patient_adherence_dates` where ((not(exists(select 1 AS `Not_used` from `obs` where ((`obs`.`concept_id` = 28) and (`obs`.`patient_id` = `patient_adherence_dates`.`patient_id`) and (`obs`.`obs_datetime` >= `patient_adherence_dates`.`visit_date`) and (`obs`.`obs_datetime` <= `patient_adherence_dates`.`default_date`))))) and (not(exists(select 1 AS `Not_used` from ((((`encounter` join `orders` on((`orders`.`encounter_id` = `encounter`.`encounter_id`))) join `drug_order` on((`drug_order`.`order_id` = `orders`.`order_id`))) join `drug` on((`drug_order`.`drug_inventory_id` = `drug`.`drug_id`))) join `concept_set` `arv_drug_concepts` on(((`arv_drug_concepts`.`concept_set` = 460) and (`arv_drug_concepts`.`concept_id` = `drug`.`concept_id`)))) where ((`encounter`.`encounter_type` = 3) and (`encounter`.`patient_id` = `patient_adherence_dates`.`patient_id`) and (`encounter`.`encounter_datetime` > `patient_adherence_dates`.`visit_date`) and (`encounter`.`encounter_datetime` <= `patient_adherence_dates`.`default_date`))))))", :force => true do |v|
    v.column :patient_id
    v.column :default_date
  end

  create_view "patient_dispensation_and_initiation_dates", "select `patient_first_line_regimen_dispensations`.`patient_id` AS `patient_id`,`patient_first_line_regimen_dispensations`.`dispensed_date` AS `start_date` from `patient_first_line_regimen_dispensations` union select `obs`.`patient_id` AS `patient_id`,`obs`.`value_datetime` AS `start_date` from `obs` where (`obs`.`concept_id` = 143)", :force => true do |v|
    v.column :patient_id
    v.column :start_date
  end

  create_view "patient_dispensations_and_prescriptions", "select `encounter`.`patient_id` AS `patient_id`,`encounter`.`encounter_id` AS `encounter_id`,cast(`encounter`.`encounter_datetime` as date) AS `visit_date`,`drug`.`drug_id` AS `drug_id`,`drug_order`.`quantity` AS `total_dispensed`,`whole_tablets_remaining_and_brought`.`total_remaining` AS `total_remaining`,`patient_prescription_totals`.`daily_consumption` AS `daily_consumption` from ((((((`encounter` join `orders` on(((`orders`.`encounter_id` = `encounter`.`encounter_id`) and (`orders`.`voided` = 0)))) join `drug_order` on((`drug_order`.`order_id` = `orders`.`order_id`))) join `drug` on((`drug_order`.`drug_inventory_id` = `drug`.`drug_id`))) join `concept_set` `arv_drug_concepts` on(((`arv_drug_concepts`.`concept_set` = 460) and (`arv_drug_concepts`.`concept_id` = `drug`.`concept_id`)))) left join `patient_whole_tablets_remaining_and_brought` `whole_tablets_remaining_and_brought` on(((`whole_tablets_remaining_and_brought`.`patient_id` = `encounter`.`patient_id`) and (`whole_tablets_remaining_and_brought`.`visit_date` = cast(`encounter`.`encounter_datetime` as date)) and (`whole_tablets_remaining_and_brought`.`drug_id` = `drug`.`drug_id`)))) left join `patient_prescription_totals` on(((`patient_prescription_totals`.`drug_id` = `drug`.`drug_id`) and (`patient_prescription_totals`.`patient_id` = `encounter`.`patient_id`) and (`patient_prescription_totals`.`prescription_date` = cast(`encounter`.`encounter_datetime` as date)))))", :force => true do |v|
    v.column :patient_id
    v.column :encounter_id
    v.column :visit_date
    v.column :drug_id
    v.column :total_dispensed
    v.column :total_remaining
    v.column :daily_consumption
  end

  create_view "patient_first_line_regimen_dispensations", "select `encounter`.`patient_id` AS `patient_id`,`encounter`.`encounter_id` AS `encounter_id`,`encounter`.`encounter_datetime` AS `dispensed_date` from `encounter` where ((`encounter`.`encounter_type` = 3) and (not(exists(select 1 AS `Not_used` from ((((`orders` join `drug_order` on((`drug_order`.`order_id` = `orders`.`order_id`))) join `drug` on((`drug_order`.`drug_inventory_id` = `drug`.`drug_id`))) join `drug_ingredient` `dispensed_ingredient` on((`drug`.`concept_id` = `dispensed_ingredient`.`concept_id`))) left join `drug_ingredient` `regimen_ingredient` on(((`regimen_ingredient`.`ingredient_id` = `dispensed_ingredient`.`ingredient_id`) and (`regimen_ingredient`.`concept_id` = 450)))) where ((`orders`.`encounter_id` = `encounter`.`encounter_id`) and isnull(`dispensed_ingredient`.`concept_id`)) group by `encounter`.`encounter_id`,`regimen_ingredient`.`ingredient_id`))))", :force => true do |v|
    v.column :patient_id
    v.column :encounter_id
    v.column :dispensed_date
  end

  create_view "patient_prescriptions", "select `encounter`.`patient_id` AS `patient_id`,`encounter`.`encounter_id` AS `encounter_id`,`prescribed_dose`.`obs_datetime` AS `prescription_datetime`,`prescribed_dose`.`value_drug` AS `drug_id`,`prescribed_dose`.`value_text` AS `frequency`,`prescribed_dose`.`value_numeric` AS `dose_amount`,`prescribed_time_period`.`value_text` AS `time_period`,(`prescribed_dose`.`value_numeric` * (`prescription_time_periods`.`time_period_days` / `prescription_frequencies`.`frequency_days`)) AS `quantity`,(`prescribed_dose`.`value_numeric` / `prescription_frequencies`.`frequency_days`) AS `daily_consumption` from ((((`encounter` join `obs` `prescribed_dose` on(((`prescribed_dose`.`concept_id` = 375) and (`prescribed_dose`.`encounter_id` = `encounter`.`encounter_id`) and (`prescribed_dose`.`value_drug` is not null) and (`prescribed_dose`.`voided` = 0)))) join `obs` `prescribed_time_period` on(((`prescribed_time_period`.`concept_id` = 345) and (`prescribed_time_period`.`encounter_id` = `encounter`.`encounter_id`) and (`prescribed_time_period`.`voided` = 0)))) join `prescription_frequencies` on((`prescription_frequencies`.`frequency` = `prescribed_dose`.`value_text`))) join `prescription_time_periods` on((`prescription_time_periods`.`time_period` = `prescribed_time_period`.`value_text`))) where (`encounter`.`encounter_type` = 2)", :force => true do |v|
    v.column :patient_id
    v.column :encounter_id
    v.column :prescription_datetime
    v.column :drug_id
    v.column :frequency
    v.column :dose_amount
    v.column :time_period
    v.column :quantity
    v.column :daily_consumption
  end

  create_view "patient_regimen_ingredients", "select `regimen_ingredient`.`ingredient_id` AS `ingredient_concept_id`,`regimen_ingredient`.`concept_id` AS `regimen_concept_id`,`encounter`.`patient_id` AS `patient_id`,`encounter`.`encounter_id` AS `encounter_id`,`encounter`.`encounter_datetime` AS `dispensed_date` from ((((((`encounter` join `orders` on((`orders`.`encounter_id` = `encounter`.`encounter_id`))) join `drug_order` on((`drug_order`.`order_id` = `orders`.`order_id`))) join `drug` on((`drug_order`.`drug_inventory_id` = `drug`.`drug_id`))) join `drug_ingredient` `dispensed_ingredient` on((`drug`.`concept_id` = `dispensed_ingredient`.`concept_id`))) join `drug_ingredient` `regimen_ingredient` on((`regimen_ingredient`.`ingredient_id` = `dispensed_ingredient`.`ingredient_id`))) join `concept` `regimen_concept` on((`regimen_ingredient`.`concept_id` = `regimen_concept`.`concept_id`))) where ((`encounter`.`encounter_type` = 3) and (`regimen_concept`.`class_id` = 18) and (`orders`.`voided` = 0)) group by `encounter`.`encounter_id`,`regimen_ingredient`.`concept_id`,`regimen_ingredient`.`ingredient_id`", :force => true do |v|
    v.column :ingredient_concept_id
    v.column :regimen_concept_id
    v.column :patient_id
    v.column :encounter_id
    v.column :dispensed_date
  end

  create_view "patient_regimens", "select `patient_regimen_ingredients`.`regimen_concept_id` AS `regimen_concept_id`,`patient_regimen_ingredients`.`patient_id` AS `patient_id`,`patient_regimen_ingredients`.`encounter_id` AS `encounter_id`,`patient_regimen_ingredients`.`dispensed_date` AS `dispensed_date` from `patient_regimen_ingredients` group by `patient_regimen_ingredients`.`encounter_id`,`patient_regimen_ingredients`.`regimen_concept_id` having (count(0) = (select count(0) AS `count(*)` from `drug_ingredient` where (`drug_ingredient`.`concept_id` = `patient_regimen_ingredients`.`regimen_concept_id`)))", :force => true do |v|
    v.column :regimen_concept_id
    v.column :patient_id
    v.column :encounter_id
    v.column :dispensed_date
  end

  create_view "patient_registration_dates", "select `encounter`.`patient_id` AS `patient_id`,`encounter`.`location_id` AS `location_id`,min(`encounter`.`encounter_datetime`) AS `registration_date` from ((((`encounter` join `orders` on((`orders`.`encounter_id` = `encounter`.`encounter_id`))) join `drug_order` on((`drug_order`.`order_id` = `orders`.`order_id`))) join `drug` on((`drug_order`.`drug_inventory_id` = `drug`.`drug_id`))) join `concept_set` `arv_drug_concepts` on(((`arv_drug_concepts`.`concept_set` = 460) and (`arv_drug_concepts`.`concept_id` = `drug`.`concept_id`)))) where (`encounter`.`encounter_type` = 3) group by `encounter`.`patient_id`,`encounter`.`location_id`", :force => true do |v|
    v.column :patient_id
    v.column :location_id
    v.column :registration_date
  end

  create_view "patient_start_dates", "select `patient_dispensation_and_initiation_dates`.`patient_id` AS `patient_id`,min(`patient_dispensation_and_initiation_dates`.`start_date`) AS `start_date` from `patient_dispensation_and_initiation_dates` group by `patient_dispensation_and_initiation_dates`.`patient_id`", :force => true do |v|
    v.column :patient_id
    v.column :start_date
  end

end
