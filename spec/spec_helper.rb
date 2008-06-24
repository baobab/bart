ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

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
  config.use_transactional_fixtures = false
  config.use_instantiated_fixtures  = false
  config.global_fixtures = :users, :location

  config.before do
    User.current_user ||= users(:mikmck)
    Location.current_location ||= location(:martin_preuss_centre)
  end

end

module Spec
  module Rails
    module Example
      class ModelExampleGroup
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
    end
  end
end  
