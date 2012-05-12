class DispensationsController < ApplicationController
  def new
    @patient = Patient.find(session[:patient_id])
    session_date = session[:encounter_datetime].to_date rescue Date.today
    encounter_type = EncounterType.find_by_name('Outpatient diagnosis')
    concept = Concept.find_by_name('Drugs given')
    observations = Observation.find(:all,
                       :joins => "INNER JOIN encounter e USING(encounter_id)",
                       :conditions =>["concept_id = ? AND encounter_type = ? AND e.patient_id = ? 
                       AND DATE(encounter_datetime) = ?",concept.id,encounter_type.id,session[:patient_id],session_date])

    @prescribe_drugs = [] 
    @encounter_id = observations.first.encounter_id
    observations.map do | obs |
      @prescribe_drugs << [obs.value_drug,obs.value_text,obs.value_numeric]  
    end
    render :layout => false
  end

  def create
    concept = Concept.find_by_name('Drugs given')
    observations = Observation.find(:all,
                :conditions =>["concept_id = ? AND encounter_id = ?",concept.id,params[:encounter_id]])


    #(params["quantity_dispensed"] || []).each do | name , drug_id |
    (observations || [] ).each do | obs |
      next if params['quantity_dispensed']["#{obs.value_drug}"].blank?
      quantity = params['quantity_dispensed']["#{obs.value_drug}"].to_f 
ActiveRecord::Base.connection.execute <<EOF
UPDATE obs SET value_numeric = #{quantity} 
WHERE obs_id = #{obs.id}
EOF
    end
    redirect_to "/" and return
  end

end
