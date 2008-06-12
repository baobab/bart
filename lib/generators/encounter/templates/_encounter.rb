class <%= form.uri.camelcase %>Controller < ApplicationController

  def new
    redirect_to(:controller => "patient", :action => "menu") and return if session[:patient].nil?
    session[:encounter] = new_encounter(EncounterType.find_by_name("<%= form.encounter_type.name %>"))
    @patient = session[:patient]
  end
  
  def create
    redirect_to(:controller => "patient", :action => "menu") and return if session[:patient_id].nil?
    parse_observations(params) 
    redirect_to(:controller => "patient", :action => "menu") and return 
  end

  def edit
  end

end
