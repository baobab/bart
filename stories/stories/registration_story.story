Story: User selecting a patient
 
  As a user
  I want to create a new patient record
 
 Scenario: User logs in and goes to the create new patient page
    Given a logged in user
    When the user clicks Register patient
    Then should redirect to 'patient/new'

  Scenario: User enter patient info and create a new patient record
