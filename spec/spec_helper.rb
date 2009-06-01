ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

# Make sure the tmp directory exists, for PDF specs
system "mkdir #{RAILS_ROOT}/tmp" unless File.exists? "#{RAILS_ROOT}/tmp"

# Load custom matchers
Dir[File.expand_path("#{File.dirname(__FILE__)}/matchers/*.rb")].uniq.each do |file|
  require file
end

Test::Unit::TestCase.class_eval do
  set_fixture_class :obs => Observation
  set_fixture_class :concept_map => ConceptMap
  set_fixture_class :concept_data_type => ConceptDatatype
  set_fixture_class :concept_name => ConceptName
  set_fixture_class :concept_numeric => ConceptNumeric
  set_fixture_class :concept_proposal => ConceptProposal
  set_fixture_class :concept_set_derived => ConceptSetDerived
  set_fixture_class :concept_set => ConceptSet
  set_fixture_class :concept_source => ConceptSource
  set_fixture_class :concept_synonym => ConceptSynonym
  set_fixture_class :concept_word => ConceptWord
  set_fixture_class :drug_ingredient => DrugIngredient
  set_fixture_class :field_answer => FieldAnswer
  set_fixture_class :field => Field
  set_fixture_class :field_type => FieldType
  set_fixture_class :form_field => FormField
  set_fixture_class :form => Form
  set_fixture_class :formentry_archive => FormentryArchive
  set_fixture_class :formentry_queue => FormentryQueue
  set_fixture_class :global_property => GlobalProperty
  set_fixture_class :heart_beat => HeartBeat
  set_fixture_class :hl7_in_archive => Hl7InArchive
  set_fixture_class :hl7_in_error => Hl7InError
  set_fixture_class :hl7_in_queue => Hl7InQueue
  set_fixture_class :hl7_source => Hl7Source
  set_fixture_class :mime_type => MimeType
  set_fixture_class :patient_address => PatientAddress
  set_fixture_class :patient_prescription_totals => PatientPrescriptionTotal
  set_fixture_class :patient_program => PatientProgram
  set_fixture_class :person => Person
  set_fixture_class :privilege => Privilege
  set_fixture_class :program => Program
  set_fixture_class :relationship => Relationship
  set_fixture_class :relationship_type => RelationshipType
  set_fixture_class :report_object => ReportObject
  set_fixture_class :report => Report
  set_fixture_class :role_privilege => RolePrivilege
  set_fixture_class :role_role => RoleRole
  set_fixture_class :role => Role
  set_fixture_class :tribe => Tribe
  set_fixture_class :user_property => UserProperty
  set_fixture_class :user_role => UserRole
end


Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.global_fixtures = :all

  config.before do
    User.current_user ||= users(:mikmck)
    Location.current_location = location(:martin_preuss_centre)
  end

end


module BaobabSpecHelpers
  @@views = {}
  @@views[:patient_dispensations_and_prescriptions] = ["DROP VIEW patient_dispensations_and_prescriptions;"]
  @@views[:patient_dispensations_and_prescriptions].push <<EOL
CREATE VIEW patient_dispensations_and_prescriptions (patient_id, encounter_id, visit_date, drug_id, total_dispensed, total_remaining, daily_consumption) AS
  SELECT encounter.patient_id,
         encounter.encounter_id,
         DATE(encounter.encounter_datetime),
         drug.drug_id,
         drug_order.quantity AS total_dispensed,
         whole_tablets_remaining_and_brought.total_remaining AS total_remaining,
         patient_prescription_totals.daily_consumption AS daily_consumption
  FROM encounter
  INNER JOIN orders ON orders.encounter_id = encounter.encounter_id AND orders.voided = 0
  INNER JOIN drug_order ON drug_order.order_id = orders.order_id
  INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
  INNER JOIN concept_set as arv_drug_concepts ON
    arv_drug_concepts.concept_set = 460 AND
    arv_drug_concepts.concept_id = drug.concept_id
  LEFT JOIN patient_whole_tablets_remaining_and_brought AS whole_tablets_remaining_and_brought ON
    whole_tablets_remaining_and_brought.patient_id = encounter.patient_id AND
    whole_tablets_remaining_and_brought.visit_date = DATE(encounter.encounter_datetime) AND
    whole_tablets_remaining_and_brought.drug_id = drug.drug_id
  LEFT JOIN patient_prescription_totals ON
    patient_prescription_totals.drug_id = drug.drug_id AND
    patient_prescription_totals.patient_id = encounter.patient_id AND
    patient_prescription_totals.prescription_date = DATE(encounter.encounter_datetime);
EOL


  def login_current_user
    session[:user_id] = User.current_user.id
  end

  def prescribe_drug(patient, drug, dose, frequency, encounter, date = nil)
    encounter ||= patient.encounters.create(:encounter_datetime => date, :encounter_type => encounter_type(:art_visit).encounter_type_id)
    encounter.observations.create(:value_drug => drug.drug_id, :value_text => frequency, :value_numeric => dose, :concept_id => concept(:prescribed_dose).concept_id, :obs_datetime => encounter.encounter_datetime)
    encounter
  end

  def dispense_drugs(patient, date, drugs)
    encounter = patient.encounters.create(:encounter_datetime => date, :encounter_type => encounter_type(:give_drugs).encounter_type_id)
    drugs.each{|hash|
      order = encounter.orders.create(:order_type_id => 1)
      drug_order = order.drug_orders.create(:drug_inventory_id => hash[:drug].drug_id, :quantity => hash[:quantity])
    }
    encounter
  end

  def create_view(view_name)
    return unless @@views.has_key? view_name
    @@views[view_name].each {|sql| ActiveRecord::Base.connection.execute sql }
  end
end

module Spec
  module Rails
    module Example
      class ModelExampleGroup
        include BaobabSpecHelpers

        # Allow the spec to define a sample hash
        def self.sample(hash, sample_key = described_type)
          @@sample ||= Hash.new
          @@sample[sample_key] = hash
        end

        # Shortcut method to create
        def create_sample(klass, options={})
          klass.create(@@sample[klass].merge(options))
        end

      end

      class ControllerExampleGroup
        include BaobabSpecHelpers
      end
    end
  end
end

