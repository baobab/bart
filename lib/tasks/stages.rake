namespace :bart do
  desc "List all patients with an HIV Staging encounter and stage defining conditions"
  task(:stages) do
    ENV["RAILS_ENV"] ||= "development"
    require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
    encounters = Encounter.find(:all, :include => [:patient, :observations], :conditions => ["encounter_type = ? ",  EncounterType.find_by_name("HIV Staging").id])
    stage_defining_conditions = Hash.new(0)
    encounters.each{|encounter|
      encounter.observations.each{|o|
        stage_defining_conditions[o.concept.name] += 1 if o.value_coded == Concept.find_by_name("Yes").id
      }
    }
    stage_defining_conditions.each{|condition, number|
      puts "#{condition} :  #{number}"
    }
  end
end
