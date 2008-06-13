require File.dirname(__FILE__) + '/../spec_helper'

describe <%= class_name %> do
  # You can move this to spec_helper.rb
  set_fixture_class :<%= actual_table_name -%> => <%= singular_name.camelize %>
  fixtures :<%= actual_table_name %>

  sample({
<% ActiveRecord::Base.connection.columns(actual_table_name).each do |col| -%>
<% if col.type == :integer -%>
    :<%= col.name -%> => 1,
<% end -%>
<% if col.type == :boolean -%>
    :<%= col.name -%> => false,
<% end -%>
<% if col.type == :date -%>
    :<%= col.name -%> => Time.now.to_date,
<% end -%>
<% if col.type == :datetime -%>
    :<%= col.name -%> => Time.now,
<% end -%>
<% if col.type == :time -%>
    :<%= col.name -%> => Time.now,
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
  })

  it "should be valid" do
    <%= singular_name -%> = create_sample
    <%= singular_name -%>.should be_valid
  end
  
end
