require File.dirname(__FILE__) + "/../helper"
with_steps_for(:registration) do
  run_local_story "registration_story.story", :type => RailsStory
end
