Story: User selecting a patient
 
  As a user
  I want to select a patient
  So that I can enter or view their details in the system
 
  Scenario: Specified patient does not exist
    Given no current patient is selected
    When the user scans 'P1111'
    Then should redirect to '/patient/menu'
    And should display error 'Sorry,Patient with id P1111 not found'
 
