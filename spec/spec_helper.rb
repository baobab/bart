ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

# Load custom matchers
Dir[File.expand_path("#{File.dirname(__FILE__)}/matchers/*.rb")].uniq.each do |file|
  require file
end

Test::Unit::TestCase.class_eval do
  set_fixture_class :obs => Observation
end


Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.global_fixtures = :users, :location

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

