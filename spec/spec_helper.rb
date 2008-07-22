ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

# Load custom matchers
Dir[File.expand_path("#{File.dirname(__FILE__)}/matchers/*.rb")].uniq.each do |file|
  require file
end

Test::Unit::TestCase.class_eval do
 set_fixture_class :concept => Concept
  set_fixture_class :drug => Drug
  set_fixture_class :encounter_type => EncounterType
  set_fixture_class :encounter => Encounter
  set_fixture_class :global_property => GlobalProperty
  set_fixture_class :location => Location
  set_fixture_class :order => Order
  set_fixture_class :order_type => OrderType
  set_fixture_class :obs => Observation
  set_fixture_class :patient => Patient
  set_fixture_class :patient_identifier_type => PatientIdentifierType
  set_fixture_class :privilege => Privilege
  set_fixture_class :program => Program
  set_fixture_class :relationship_type => RelationshipType
  set_fixture_class :role => Role
  set_fixture_class :role_privilege => RolePrivilege
  set_fixture_class :user_role => UserRole
  set_fixture_class :users => User
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
end

module Spec
  module Rails
    module Example
      class ModelExampleGroup
        include BaobabSpecHelpers

        # Allow the spec to define a sample hash
        def self.sample(hash)
          @@sample ||= Hash.new
          @@sample[described_type] = hash   
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

