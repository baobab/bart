require File.dirname(__FILE__) + '/../test_helper'

class DrugTest < Test::Unit::TestCase
  # You can move this to test_helper.rb
  set_fixture_class :drugs => Drug
  fixtures :drug, :users, :location

  cattr_reader :drug_default_values
  @@drug_default_values = {
    :drug_id => 1999,
    :concept_id => 1,
    :name => '',
    :combination => false,
    :dosage_form => '',
    :inn => '',
    :route => '',
    :shelf_life => 0,
    :therapy_class => 0,
    :units => '',
    :creator => 1,
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
    drug = create
    assert drug.valid?, "Drug was invalid:\n#{drug.to_yaml}"
  end

  def test_should_return_abbreviation
    drug = create(:name => 'Stavudine 30 Lamivudine 150')
    assert_equal "SL: ", drug.to_abbreviation
  end

  def test_should_return_arv_as_false
    drug = create(:name => 'Stavudine 30 Lamivudine 150')
    assert_equal false, drug.arv?
  end

  def test_should_return_arv_as_true
    drug = create(:name => 'Stavudine 30 Lamivudine 150')
    drug = drug(:drug_00001)
    assert_equal true, drug.arv?
  end

private

  def create(options={})
    Drug.create(drug_default_values.merge(options))
  end

end
