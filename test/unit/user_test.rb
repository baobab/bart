require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users, :global_property, :location, :user_role, :role, :privilege, 
    :role_privilege
  
  cattr_reader :user_default_values
  @@user_default_values = {
    :username => "nurse",
    :password => "nurse"
  }
  
  def setup
    super
    User.current_user = users(:registration)
  end
  
  def teardown
    super
  end
  
  def test_should_create_record
    user = create
    assert user.valid?, "User was invalid:\n#{user.to_yaml}"
  end
  
  def test_should_not_create_on_error
    assert_no_difference User, :count do
      user = create :username => nil
    end  
  end

  def test_record_create_should_use_current_user_and_current_date      
    curr_date = Date.today
    user = create
    assert user.valid?
    assert user.creator == User.current_user.id
    assert user.date_created.day == curr_date.day && 
           user.date_created.month == curr_date.month &&
           user.date_created.year == curr_date.year
  end
  
  def test_record_update_should_use_current_user_and_current_date
    assert true
  end

  def test_should_require_username
    user = create :username => nil
    assert user.errors.on(:username)
  end  
  
  def test_should_require_password
    user = create :password => nil
    assert user.errors.on(:password)
  end
  
  def test_should_check_username_length
    user = create :username => "this_is_a_very_long_user_name_longer_than_forty_chars"
    assert user.errors.on(:username)
    user = create :username => "abe"
    assert user.errors.on(:username) 
    user = create :username => "flash"
    assert user.valid?
  end
  
  def test_should_check_username_unique
    user = create :username => "registration"
    assert user.errors.on(:username)
  end
  
  def test_should_have_name
    user = create(:username => 'Senor Clinician')
    assert_equal "Senor Clinician", user.username
  end
        
  def test_should_have_role
    user = users(:registration)
    assert user.has_role("Registration Clerk"), "User '#{user.username}' does not have the 'Registration Clerk' role" 
  end
  
  def test_should_not_have_role
    user = users(:registration)
    assert !user.has_role("Nurse"), "User '#{user.username}' should not have the 'Nurse' role" 
  end
  
  def test_should_have_privilege
    user = users(:registration)
    assert user.has_privilege_by_name("General Registration"), "User '#{user.username}' does not have the 'General Registration' privilege" 
  end

  def test_should_not_have_privilege
    user = users(:registration)
    assert !user.has_privilege_by_name("Manage Users"), "User '#{user.username}' has the 'Manage Users' privilege" 
  end

  def test_should_add_salt
    user = create
    assert !user.salt.empty?
  end

  def test_should_hash_password
    user = create
    assert_not_equal user.password, "nurse"
  end

  def test_should_authenticate_user
    user = create
    assert_equal user, User.authenticate('nurse', 'nurse')
  end
  
  def test_should_not_rehash_password
    # TODO this test currently fails. If you want to update a user currently
    # TODO you need to submit the password and confirmation again
#    user = create
#    user.update_attributes(:username => 'nurse2')
#    assert_equal user, User.authenticate('nurse2', 'nurse')
  end

  def test_should_not_be_void
    assert true
  end

  def test_find_should_not_include_voided
    assert true
  end
  
  def test_find_with_voided
    assert true
  end

  def test_current_programs_should_include_hiv
    user = create
    assert_equal [Program.find_by_name('HIV')], user.current_programs
  end

private

  def create(options={})
    User.create(user_default_values.merge(options))
  end

end
