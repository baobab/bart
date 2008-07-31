Story: User selecting a patient
 
  As a user
  I want to select a patient
  So that I can enter or view their details in the system
 
  Scenario: Specified patient does not exist
    Given no current patient is selected
    When the user scans 'P1111'
    Then should redirect to '/patient/menu'
    And should display text 'Sorry,Patient with id P1111 not found'
  
  Scenario: Specified patient exists and no patient is already selected
    Given no current patient is selected
    When the user scans 'P170000000013'
    Then should redirect to 'patient/patient_detail_summary'
  
  Scenario: Specified patient exists and a patient is already selected
    Given a patient 'P170100176493' is selected
    When the user scans 'P170000000013'
    Then should redirect to 'patient/patient_detail_summary'
    And should display text 'Andreas Jahn'

