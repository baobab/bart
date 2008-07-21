Story: lab data migration - from healthdata to openmrs
 
  As a user
  I want to login with my details
  So that I can get access to the function of moving patients' lab data from one database to another
 
  Scenario: User logs in and selects a task(s) from the list of tasks
    Given a logged in user 
    And a task 
    When the user clicks on finish
  
  Scenario: User clicks on Administration
    Given a logged in user 
    And a task 
    When the user clicks on administration
    Then should redirect to '/patient/admin_menu'
  
  Scenario: User clicks on Synchronize
    Given a logged in user 
    And a task 
    When the user clicks on administration
    Then should redirect to '/patient/admin_menu'
    When the user clicks on Synchronize

  Scenario: User synchronize data
    Given a logged in user 
    And a task 
    When the user clicks on administration
    Then should redirect to '/patient/admin_menu'
    When the user clicks on Synchronize
    Then should redirect to '/patient/synchronize'
    When the user clicks on Sync Lab data
