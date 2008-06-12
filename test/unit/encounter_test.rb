require File.dirname(__FILE__) + '/../test_helper'

class EncounterTest < Test::Unit::TestCase
  # You can move this to test_helper.rb
  set_fixture_class :encounters => Encounter
  fixtures :encounter, :encounter_type, :obs, :concept, :users, :location

  cattr_reader :encounter_default_values
  @@encounter_default_values = {
    :encounter_id => 1,
    :encounter_type => 1,
    :patient_id => 1,
    :provider_id => 1,
    :location_id => 1,
    :form_id => 1,
    :encounter_datetime => '2000-01-01 00:00:00',
    :creator => 1,
    :date_created => '2000-01-01 00:00:00'
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
    encounter = create
    assert encounter.valid?, "Encounter was invalid:\n#{encounter.to_yaml}"
  end

  def test_should_write_observations_to_label
    label = ZebraPrinter::Label.new
    encounter = encounter(:andreas_art_visit)
    encounter.to_label(label)
#TODO    assert_equal "\nN\nq776\nQ329\nZT\nA13,0,0,1,1,1,R,\"ART Visit\"\nA13,26,0,1,1,1,N,\"Walk:Y, Whole tablets remaining but not brought to clinic:SLN: , 7.0,\"\nA13,52,0,1,1,1,N,\"Whole tablets remaining and brought to clinic:SLN: , 10.0, Whole tablets\"\nA13,78,0,1,1,1,N,\"remaining but not brought to clinic:A: , 7.0, Whole tablets remaining and\"\nA13,104,0,1,1,1,N,\"brought to clinic:10.0\"\nP1\n", label.print(1)
  end
  
  def test_should_write_visit_label_for_encounter
    @visit_label = ZebraPrinter::VisitLabel.from_encounters([encounter(:andreas_art_visit)])
#TODO    assert_equal "\nN\nq776\nQ329\nZT\nA13,13,0,3,1,1,R,\"ART Visit\"\nA13,49,0,3,1,1,N,\"Walk:Y, Whole tablets remaining but not\"\nA13,85,0,3,1,1,N,\"brought to clinic:SLN: , 7.0, Whole tablets\"\nA13,121,0,3,1,1,N,\"remaining and brought to clinic:SLN: ,\"\nA13,157,0,3,1,1,N,\"10.0, Whole tablets remaining but not\"\nA13,193,0,3,1,1,N,\"brought to clinic:A: , 7.0, Whole tablets\"\nA13,229,0,3,1,1,N,\"remaining and brought to clinic:10.0\"\nP1\n", @visit_label.print(1)
  end


private

  def create(options={})
    Encounter.create(encounter_default_values.merge(options))
  end

end
