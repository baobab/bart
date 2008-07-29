Story: lab data migration - from healthdata to openmrs
 
  As a user
  I want to login with my details
  So that I can get access to the function of moving patients' lab data from one database to another
 
  Scenario: User logs in
    Given a logged in user 
    When the user clicks Done
    Then should redirect to '/user/activities'
  
  Scenario: User selects a task(s) from the list of tasks
    Given a logged in user 
    And a task 
    When the user clicks Done
    Then should redirect to '/user/activities'
    When the user clicks Finish
    Then should redirect to '/patient/menu'

  Scenario: User clicks Administration
    Given a logged in user 
    And a task 
    And a list of choices on the patient menu
    When the user clicks Done
    Then should redirect to '/user/activities'
    When the user clicks Finish
    Then should redirect to '/patient/menu'
    When the user clicks Administration
    Then should redirect to '/patient/admin_menu'
  
  Scenario: User clicks Synchronize

  Scenario: User synchronize data
