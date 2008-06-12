require File.dirname(__FILE__) + '/../test_helper'

class ConceptTest < Test::Unit::TestCase
  fixtures :concept, :concept_class, :users, :location

  cattr_reader :concept_default_values
  @@concept_default_values = {
    :retired => false,
    :name => 'Default',
    :short_name => 'Def',
    :description => 'A Default Concept',
    :form_text => 'Please enter the value for the default concept',
    :datatype_id => 1,
    :class_id => 1,
    :is_set => false,
    :icd10 => '',
    :loinc => '',
    :creator => 1,
    :date_created => '2000-01-01 00:00:00',
    :default_charge => 0,
    :version => '1.0',
    :changed_by => 0,
    :date_changed => '2000-01-01 00:00:00',
    :form_location => '',
    :units => '',
    :view_count => 0
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
    concept = create
    assert concept.valid?, "Concept was invalid:\n#{concept.to_yaml}"
  end

private

  def create(options={})
    Concept.create(concept_default_values.merge(options))
  end

end
