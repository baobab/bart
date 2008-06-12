require File.dirname(__FILE__) + '/../test_helper'

class PrivilegeTest < Test::Unit::TestCase
  fixtures :privilege
  
  cattr_reader :privilege_default_values
  @@privilege_default_values = {
    :description => "ART Initiation",
    :privilege_id => 15,
    :privilege => "ART Initiation"    
  }
  
  def test_should_create_record
    privilege = create
    assert privilege.valid?, "Privilege was invalid:\n#{privilege.to_yaml}"
  end
  
private

  def create(options={})
    Privilege.create(privilege_default_values.merge(options))
  end

end
