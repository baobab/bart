Story: User enters patient and guardian availability
 
  As a registration clear
  I want to indication if patient and/or guardian are present
  So that the system can suggest appropriate questions to other users
 
  Scenario: Only the patient is present
    Given a patient 'P170100176493' is selected on reception
    When user enters Guardian present 'No' and Patient present 'Yes'
    Then should redirect to '/patient/menu?'
    And observations for last encounter for patient 'P170100176493' should be 'Guardian present: No,Patient present: Yes'
 #   And should display text '<b>Completed task</b>\n    \n    <a href=\"/patient/encounters\" id=\"patient_encounters\" onClick=\"return false\" onMouseDown=\"this.style.backgroundColor=\'lightblue\';document.location=this.href\" style=\"text-align: left; display: inline; width: 80px; font-size: 1.2em; text-decoration: underline;\">[Edit]</a>\n    <br/>\n      HIV Reception<br/>'
  
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
    
