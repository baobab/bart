require File.dirname(__FILE__) + '/../test_helper'

class ObservationTest < Test::Unit::TestCase
  fixtures :obs, :users, :location, :concept

  cattr_reader :observation_default_values
  @@observation_default_values = {
    :obs_id => 1,
    :patient_id => 1,
    :concept_id => 1,
    :encounter_id => 1,
    :order_id => 1,
    :obs_datetime => '2000-01-01 00:00:00',
    :location_id => 1,
    :obs_group_id => 1,
    :accession_number => '',
    :value_group_id => 1,
    :value_boolean => false,
    :value_coded => 1,
    :value_drug => 1,
    :value_datetime => '2000-01-01 00:00:00',
    :value_modifier => '',
    :value_text => '',
    :date_started => '2000-01-01 00:00:00',
    :date_stopped => '2000-01-01 00:00:00',
    :comments => '',
    :creator => 1,
    :date_created => '2000-01-01 00:00:00',
    :voided => false,
    :voided_by => 0,
    :date_voided => '2000-01-01 00:00:00',
    :void_reason => '',
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
    observation = create
    assert observation.valid?, "Observation was invalid:\n#{observation.to_yaml}"
  end

  def test_should_display_short_string
    obs = obs(:andreas_art_visit_is_able_to_walk)
    assert_equal "Walk:Y", obs.to_short_s
  end

  def test_should_display_long_names_if_short_name_is_not_set
    weight = concept(:weight)
    weight.short_name = nil
    weight.save
    obs = obs(:andreas_vitals_height)
    assert_equal "Weight:66.0", obs.to_short_s
  end

private

  def create(options={})
    Observation.create(observation_default_values.merge(options))
  end

end
