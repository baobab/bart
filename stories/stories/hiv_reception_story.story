Story: User enters patient and guardian availability
 
  As a registration clear
  I want to indication if patient and/or guardian are present
  So that the system can suggest appropriate questions to other users
 
  Scenario: Only the patient is present
    Given a patient 'P170100176493' is selected on reception
    When user enters Guardian present 'No' and Patient present 'Yes'
    Then should redirect to '/patient/menu?'
    And observations for last encounter for patient 'P170100176493' should be 'Guardian present: No,Patient present: Yes'
    And should display texts '[Edit]' and 'HIV Reception'

    # We need to see HIV Recetion under Completed Tasks not under Next task  
    # And should display text 'HIV Reception' and 'Next'
  
  Scenario: Only the guardian is present
    Given a patient 'P170100176493' is selected on reception
    When user enters Guardian present 'Yes' and Patient present 'No'
    Then should redirect to '/patient/menu?'
    And observations for last encounter for patient 'P170100176493' should be 'Guardian present: Yes,Patient present: No'
   
  Scenario: Both the guardian and patient are present
    Given a patient 'P170100176493' is selected on reception
    When user enters Guardian present 'Yes' and Patient present 'Yes'
    Then should redirect to '/patient/menu?'
    And observations for last encounter for patient 'P170100176493' should be 'Guardian present: Yes,Patient present: Yes'
    
