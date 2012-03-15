Story: View patients' mastercard
 
  As a user
  I want to login with my details
  So that I can view a selected patient mastercard

 Scenario: User selects a patient 
    Given a selected patient
    And a selected patient main menu
    When the user scans 'P170000000013'
    Then should redirect to 'patient/patient_detail_summary'

  
  Scenario: User clicks on Mastercard
    Given a selected patient
    And a selected patient main menu
    When the user scans 'P170000000013'
    Then should redirect to 'patient/patient_detail_summary'
    When a user clicks on mastercard 
    Then should redirect to 'patient/mastercard/1'

