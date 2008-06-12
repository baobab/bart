require File.dirname(__FILE__) + '<%= '/..' * class_nesting_depth %>/../test_helper'

class <%= class_name %>Test < Test::Unit::TestCase
  # You can move this to test_helper.rb
  set_fixture_class :<%= plural_name -%> => <%= singular_name.camelize %>
  fixtures :<%= table_name %>, :users, :location

  cattr_reader :<%= singular_name -%>_default_values
  @@<%= singular_name -%>_default_values = {
<% ActiveRecord::Base.connection.columns(model_name.classify.constantize.table_name).each do |col| -%>
<% if col.type == :integer -%>
    :<%= col.name -%> => 0,
<% end -%>
<% if col.type == :boolean -%>
    :<%= col.name -%> => false,
<% end -%>
<% if col.type == :date -%>
    :<%= col.name -%> => '2000-01-01',
<% end -%>
<% if col.type == :datetime -%>
    :<%= col.name -%> => '2000-01-01 00:00:00',
<% end -%>
<% if col.type == :time -%>
    :<%= col.name -%> => '00:00:00',
<% end -%>
<% if col.type == :decimal -%>
    :<%= col.name -%> => 0.0,
<% end -%>
<% if col.type == :string -%>
    :<%= col.name -%> => '',
<% end -%>
<% if col.type == :text -%>
    :<%= col.name -%> => '',
<% end -%>
<% end -%>
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
    <%= singular_name -%> = create
    assert <%= singular_name -%>.valid?, "<%= singular_name.humanize -%> was invalid:\n#{<%= singular_name -%>.to_yaml}"
  end

private

  def create(options={})
    <%= singular_name.camelize -%>.create(<%= singular_name -%>_default_values.merge(options))
  end

end
