Story: User logging in
 
  As a user
  I want to login with my details
  So that I can get access to the medical record system
 
  Scenario: User is not logged in
    Given no current user
    When the user accesses a page
    Then should redirect to '/user/login'
 
  Scenario: User uses wrong password
    Given a username 'mikmck'
    And a password 'ticklemeelmo'
    And a location '7001'
    When the user logs in with username and password
    Then the login form should be shown again
    And should show message 'Invalid Username or Password'
 
  Scenario: User uses correct password
    Given a username 'mikmck'
    And a password 'mike'
    And a location '7001'
    When the user logs in with username and password
    Then should redirect to '/user/activities'