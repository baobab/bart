require File.dirname(__FILE__) + "/../helper"
with_steps_for(:view_mastercard) do
run_local_story "view_mastercard_story.story", :type => RailsStory
end
