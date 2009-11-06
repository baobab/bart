class DiagnosisController < ApplicationController

  def list
    concepts = Concept.find(:all,
                 :joins => "INNER JOIN concept_set s ON concept.concept_id=s.concept_id",
                 :conditions => ["s.concept_set=? AND concept.name LIKE '%#{params[:value]}%'",27])
    render :text => @options = concepts.collect{|concept|"<li>#{concept.name}</li>"}
    return
  end
  
  def new
    concepts = Concept.find(:all,
                 :joins => "INNER JOIN concept_set s ON concept.concept_id=s.concept_id",
                 :conditions => ["s.concept_set=? AND concept.name LIKE '%#{params[:value]}%'",27])
    @options = concepts.collect{|concept|concept.name}
    @patient = Patient.find(session[:patient_id]) rescue nil
    if @patient.blank?
      redirect_to :controller => "patient",:action => "menu" and return
    end  
  end

  def create
    patient = Patient.find(params[:encounter][:patient_id]) rescue nil
    raise nil if patient.blank?

    encounter_types = EncounterType.find(:all,:conditions =>["name IN ('Outpatient diagnosis','Referred')"])
    outpatient_type = encounter_types.first.id
    referred_type = encounter_types.last.id

    enc_type_id = outpatient_type if params[:select] == "option2"
    enc_type_id = referred_type if params[:select] == "option1"

    encounter = Encounter.find(:first,:conditions=>["patient_id=? AND encounter_type=? AND DATE(encounter_datetime)=?",patient.id,enc_type_id,session[:encounter_datetime].to_date])

    if encounter.blank?
      encounter = Encounter.new() 
      if params[:select] == "option2"
        encounter.encounter_type = outpatient_type
      elsif params[:select] == "option1"
        encounter.encounter_type = referred_type
      end  
      encounter.patient_id = patient.id
      encounter.encounter_datetime = session[:encounter_datetime].to_time
      encounter.provider_id = User.current_user.id
      encounter.save
    end

    if params[:select] == "option2"
      diagnosis = {}
      diagnosis["Primary diagnosis"] = params[:primary_diagnosis]
      diagnosis["Secondary diagnosis"] = params[:secondary_diagnosis]

      diagnosis.each{|key,values|
        values.split(',').each{|value|
          diagnosis_obs = Observation.new
          diagnosis_obs.encounter = encounter
          diagnosis_obs.patient_id = patient.id
          diagnosis_obs.concept = Concept.find_by_name(key)
          diagnosis_obs.value_coded = Concept.find_by_name(value).id
          diagnosis_obs.obs_datetime = encounter.encounter_datetime
          diagnosis_obs.save
        }
      }
    elsif params[:select] == "option1"
      location_id = Location.find_by_name(params[:location_name]).id 
      obs = Observation.new
      obs.encounter = encounter
      obs.patient_id = patient.id
      obs.value_numeric = location_id
      obs.concept = Concept.find_by_name("Referred to destination")
      obs.obs_datetime = encounter.encounter_datetime
      obs.save
    end
    render :text => "Saved" and return
  end

end
