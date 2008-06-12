require File.dirname(__FILE__) + '<%= '/..' * controller_class_nesting_depth %>/../test_helper'
require '<%= controller_file_path %>_controller'
require 'unit/<%= singular_name -%>_test'

# Re-raise errors caught by the controller.
class <%= controller_class_name %>Controller; def rescue_action(e) raise e end; end

class <%= controller_class_name %>ControllerTest < Test::Unit::TestCase
  fixtures :<%= table_name %>

  def setup
    @controller = <%= controller_class_name %>Controller.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_require_login
    assert_requires_login { |c| c.get :index }
    assert_requires_login { |c| c.get :new }
    assert_requires_login { |c| c.get :show, :id => 1 }
    assert_requires_login { |c| c.get :edit, :id => 1 }
    assert_requires_login { |c| c.post :create, :<%= file_name -%> => { } }
    assert_requires_login { |c| c.put :update, :id => 1, :<%= file_name -%> => { } }
    assert_requires_login { |c| c.delete :destroy, :id => 1 }
  end

  def test_should_get_index
    login
    get :index
    assert_response :success
    assert assigns(:<%= table_name %>)
  end

  def test_should_get_new
    login
    get :new
    assert_response :success
  end
  
  def test_should_create_<%= file_name %>
    login
    assert_difference <%= class_name %>, :count do
      post :create, :<%= file_name %> => <%= class_name %>Test.<%= singular_name %>_default_values
      assert_redirected_to <%= table_name %>_path
    end
  end

  def test_should_show_<%= file_name %>
    login
    get :show, :id => 1
    assert_response :success
  end

  def test_should_update_<%= file_name %>
    login
    put :update, :id => 1, :<%= file_name %> => <%= class_name %>Test.<%= singular_name %>_default_values
    assert_redirected_to <%= table_name %>_path
  end
  
  def test_should_destroy_<%= file_name %>
    login
    assert_difference <%= class_name %>, :count, -1 do
      delete :destroy, :id => 1
      assert_redirected_to <%= table_name %>_path
    end
  end
end
