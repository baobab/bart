ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'fpdf_test_helper'
require 'login_test_helper'

class Test::Unit::TestCase
  include LoginTestHelper
  include FPDFTestHelper

  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  # Assign the fixture classes once, this keeps the tests DRY, but will add
  # class hash associations which are not necessary for some tests  
  set_fixture_class :concept => Concept
  set_fixture_class :drug => Drug
  set_fixture_class :encounter_type => EncounterType
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

  def assert_difference(object, method = nil, difference = 1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference, object.send(method), "#{object}##{method}"
  end

  def assert_no_difference(object, method, &block)
    assert_difference object, method, 0, &block
  end

  def login(username = :mikmck)
    login_as username
  end
  
  def prescribe_drug_to(patient, drug)
    raise NotImplementedError
  end
  
  def give_drug_to(patient, drug, quantity = 60, today = Time.now)
    encounter = patient.encounters.create(:encounter_type => EncounterType.find_by_name("Give drugs").id, :provider_id => User.current_user.id, :encounter_datetime => today)
    order = encounter.orders.create(:order_type_id => 1)
    drug_order = order.drug_orders.create(:drug_inventory_id => drug.id, :quantity => quantity)
  end
end
                                                                        
class ActionController::IntegrationTest
  
  def login(username = :mikmck, password = :mike, location = 701)
    post "/user/login", "user[username]" => "#{username}", "user[password]" => "#{password}", "location" => "#{location}"
    assert_redirected_to :action => 'activities'
  end

  def select_tasks(activities = nil)
    activities = Privilege.find(:all).map(&:privilege) unless activities
    post "/user/change_activities", "user[activities]" => activities
    assert_redirected_to :controller => 'patient', :action => 'menu'
  end

  def scan_patient(identifier, patient_id = nil)
    get "/encounter/scan", "barcode" => identifier
    assert_redirected_to patient_id.blank? ? "/patient/menu" : "/patient/set_patient/#{patient_id}"    
    set_patient(patient_id) unless patient_id.blank?
  end
  
  def set_patient(patient_id)
    get "/patient/set_patient/#{patient_id}"
    #assert_redirected_to '/patient/menu'
    #assert_redirected_to '/patient/add_program'
    #assert_redirected_to '/patient/patient_detail_summary'
    #assert_redirected_to '/patient/set_datetime_for_retrospective_entry'
  end

end 
