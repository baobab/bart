Story: Entering patients' vital results
 
  As a user
  I want to select a patient
  So that I can enter patients hieght and weight
 
 Scenario: User selects a patient and gets ready to enter vitals
    Given a logged in user
    And a task
    When the user clicks Finish
    Then should redirect to '/patient/menu' 
    When the user scans 'P170000000013'
    Then should redirect to '/patient/patient_detail_summary'
    When a user clicks Next
    Then should redirect to '/form/show/47'

  Scenario: User enters patients' vitals
    Given a logged in user
    And a task
    When the user clicks Finish
    Then should redirect to '/patient/menu' 
    When the user scans 'P170000000013'
    Then should redirect to '/patient/patient_detail_summary'
    When a user clicks Next
    Then should redirect to '/form/show/47'
    When the user enters the vitals and clicks Finish
    Then should redirect to '/patient/menu'
