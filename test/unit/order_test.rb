require File.dirname(__FILE__) + '/../test_helper'

class OrderTest < Test::Unit::TestCase
  fixtures :orders, :order_type, :encounter, :users, :location, :patient

  cattr_reader :order_default_values
  @@order_default_values = {
    :order_id => 1,
    :order_type_id => 1,
    :encounter_id => 1,
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
    order = create
    assert order.valid?, "Order was invalid:\n#{order.to_yaml}"
  end

  def test_should_find_patient
    # for some reason using order(:name) fails in newer version of rails
    order = Order.find(1) 
    p = order.patient
    assert_equal patient(:andreas), p
  end

private

  def create(options={})
    Order.create(order_default_values.merge(options))
  end

end
