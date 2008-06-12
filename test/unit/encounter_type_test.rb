require File.dirname(__FILE__) + '/../test_helper'

class EncounterTypeTest < Test::Unit::TestCase
  # You can move this to test_helper.rb
  set_fixture_class :encounter_types => EncounterType
  fixtures :encounter_type, :users, :location

  cattr_reader :encounter_type_default_values
  @@encounter_type_default_values = {
    :encounter_type_id => 1,
    :name => '',
    :description => '',
    :creator => 0,
    :date_created => '2000-01-01 00:00:00',
  }

  def setup
    super
    User.current_user = users(:registration)
    Location.current_location = location(:martin_preuss_centre)
  end
  
  def teardown
    super
    User.current_user = nil
    Location.current_location = nil
  end

  def test_should_create_record
    encounter_type = create
    assert encounter_type.valid?, "Encounter type was invalid:\n#{encounter_type.to_yaml}"
  end

private

  def create(options={})
    EncounterType.create(encounter_type_default_values.merge(options))
  end

end
