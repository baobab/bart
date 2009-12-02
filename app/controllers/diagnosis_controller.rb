class DiagnosisController < ApplicationController

  def list
    concept = Concept.find_by_name('MALAWI NATIONAL DIAGNOSIS')
    diagnosis_concepts = Concept.find(:all, :joins => :concept_sets,
              :conditions => ["concept_set = ? AND concept.name LIKE '%#{params[:value]}%'", concept.concept_id])

    render :text => @options = diagnosis_concepts.collect{|concept|"<li>#{concept.name}</li>"}
    return
  end
  
  def new
    concept = Concept.find_by_name('Malawi national diagnosis')
    diagnosis_concepts = Concept.find(:all, :joins => :concept_sets,
                                      :conditions => ['concept_set = ?', concept.concept_id])
    @options = ['']
    diagnosis_concepts.collect{|concept|
      next if concept.name == 'Malawi national diagnosis' 
      next if concept.name == 'Not applicable' 
      @options << concept.name
    }
    @patient = Patient.find(session[:patient_id]) rescue nil


#    @drugs = Drug.find(:all,:order =>"name ASC").map {|drug|drug.name unless drug.arv?}
     concept_set = Concept.find_by_name("CMERD drugs").id
     @drugs = Drug.find(:all,
                        :joins => "INNER JOIN concept c ON drug.concept_id=c.concept_id
                        INNER JOIN concept_set s ON s.concept_id=c.concept_id",
                        :conditions =>["s.concept_set=?",concept_set]).map {|drug|drug.name} rescue nil

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
        values.each{|value|
          next if value.blank?
          next if value == "Other"
          diagnosis_obs = Observation.new
          diagnosis_obs.encounter_id = encounter.encounter_id
          diagnosis_obs.patient_id = patient.id
          diagnosis_obs.concept_id = Concept.find_by_name(key).id
          diagnosis_obs.value_coded = Concept.find_by_name(value).id
          diagnosis_obs.obs_datetime = encounter.encounter_datetime
          diagnosis_obs.save
        }
      }


      if params[:treatment]
        drugs_given = Concept.find_by_name("Drugs given")
        params[:treatment].each{|drug_name|
          next if drug_name == 'Not applicable' 
          next if drug_name.blank?
          drug = Drug.find_by_name(drug_name)
          next if drug.blank?
          gave_drug = Observation.new
          gave_drug.encounter_id = encounter.encounter_id
          gave_drug.patient_id = patient.id
          gave_drug.concept_id = drugs_given.id
          gave_drug.value_numeric = drug.concept_id
          gave_drug.value_drug = drug.id
          gave_drug.value_text = drug.name
          gave_drug.obs_datetime = encounter.encounter_datetime
          gave_drug.save
        }
      end  

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
    redirect_to :controller => "patient",:action => "menu" and return
  end

end
