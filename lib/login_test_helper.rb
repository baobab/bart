module LoginTestHelper

  # Sets the current user in the session from the user fixtures.
  def login_as(user)
    User.current_user = user ? users(user) : nil
    @request.session[:user_id] = User.current_user.id
  end

  # Assert the block redirects to the login
  #
  #   assert_requires_login(:bob) { |c| c.get :edit, :id => 1 }
  #
  def assert_requires_login(login = nil)
    yield HttpLoginProxy.new(self, login)
  end

  def reset!(*instance_vars)
    instance_vars = [:controller, :request, :response] unless instance_vars.any?
    instance_vars.collect! { |v| "@#{v}".to_sym }
    instance_vars.each do |var|
      instance_variable_set(var, instance_variable_get(var).class.new)
    end
  end
end

class BaseLoginProxy
  attr_reader :controller
  attr_reader :options
  def initialize(controller, login)
    @controller = controller
    @login      = login
  end

  private
    def method_missing(method, *args)
      @controller.reset!
      authenticate
      @controller.send(method, *args)
      check
    end
end

class HttpLoginProxy < BaseLoginProxy
  protected
    def authenticate
      @controller.login_as @login if @login
    end

    def check
      @controller.assert_redirected_to :controller => 'user', :action => 'login'
    end
end
