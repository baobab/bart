require File.dirname(__FILE__) + "/../helper"
with_steps_for(:print_national_id) do
run_local_story "print_national_id_story.story", :type => RailsStory
end
