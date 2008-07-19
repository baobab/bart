Story: lab data migration - from healthdata to openmrs
 
  As a user
  I want to login with my details
  So that I can get access to the function of moving patients' lab data from one database to another
 
  Scenario: User uses correct password
    Given a username 'mikmck'
    And a password 'mike'
    And a location '701'
    When the user logs in with username and password
   
  Scenario: User selects task/s from the list of tasks
    Given a logged in user 
    And a task 'HIV Reception'
    When the user submits the task
    Then should redirect to '/patient/menu'
