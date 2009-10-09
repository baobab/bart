class PeopleController < ApplicationController
   def demographics
     # Search by the demographics that were passed in from remote server and then return demographics
    people = Patient.find_by_demographics(params)
    #result = people.empty? ? {} : people
    render :text => people.to_json
  end

end
