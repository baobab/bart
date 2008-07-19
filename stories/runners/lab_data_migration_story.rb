require File.dirname(__FILE__) + "/../helper"
with_steps_for(:lab_data_migration) do
  run_local_story "lab_data_migration_story.story", :type => RailsStory
end
