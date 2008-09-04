require File.dirname(__FILE__) + "/../helper"
with_steps_for(:enter_patient_vitals) do
  run_local_story "enter_patient_vitals_story.story", :type => RailsStory
end
