namespace :bart do
  namespace :retrospective do
    desc "Retrospectively enter the occupations for a set of patients from the patient register"  
    task(:occupation) do
      ENV["RAILS_ENV"] ||= "production"
      require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
      ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
      ro = RetrospectiveOccupation.new
      ro.execute
    end
    
    desc "Retrospectively enter the outcomes for a set of patients from the patient register"  
    task(:outcome) do
      ENV["RAILS_ENV"] ||= "production"
      require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
      ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
      ro = RetrospectiveOutcome.new
      ro.execute
    end    
  end
end			