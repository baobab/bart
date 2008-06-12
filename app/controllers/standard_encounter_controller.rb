class StandardEncounterController < ApplicationController
  def new_art_visit
    @art_visit_type_id = EncounterType.find_by_name("ART Visit").id
    @patient = Patient.find(params[:patient_id])
    @patient_id = @patient.id
  end

  def add_outcome_died
    @patient = Patient.find(params[:patient_id])
    @patient.set_outcome("Dead",params[:date])
    redirect_to :action => "menu", :patient_id => params[:patient_id]
  end

  def create_art_visit
    patient_id = params[:observations][:weight][:patient_id]
    patient = Patient.find(patient_id)

    art_visit_encounter = Encounter.create(params[:encounter])
    visit_time = art_visit_encounter.encounter_datetime

    height_weight_encounter = Encounter.new
    height_weight_encounter.provider = User.current_user
    height_weight_encounter.type = EncounterType.find_by_name("Height/Weight")
    height_weight_encounter.encounter_datetime = visit_time
    height_weight_encounter.patient_id = patient_id
    height_weight_encounter.save

    params[:observations].keys.each{|obs_type|
      if obs_type == "weight"
        encounter = height_weight_encounter
      else
        encounter = art_visit_encounter
      end

      other_obs_data = {:encounter_id => encounter.id, 
                        :obs_datetime => encounter.encounter_datetime}
      Observation.create(params[:observations][obs_type].update(other_obs_data)) rescue raise obs_type
    }

    [["Prescribe recommended dosage","Yes"],["Is able to walk unaided","Yes"],["Prescribe Cotrimoxazole (CPT)","Yes"],["Is at work/school","Yes"],["Peripheral neuropathy","No"],["Hepatitis","No"],["Continue treatment at current clinic","Yes"],["Skin rash","No"],["Prescription time period","2 weeks"],["Lactic acidosis","No"],["Lipodystrophy","No"],["ARV regimen","Stavudine Lamivudine + Stavudine Lamivudine Nevirapine"],["Anaemia","No"],["Refer patient to clinician","No"],["Other side effect","No"]].each{|obs_concept_and_answer|

      obs_concept, obs_answer_concept = obs_concept_and_answer
      observation = Observation.new
      observation.patient_id = patient_id
      observation.encounter = art_visit_encounter
      observation.obs_datetime = visit_time
      observation.concept = Concept.find_by_name(obs_concept)
      observation.answer_concept = Concept.find_by_name(obs_answer_concept)
      observation.save!
    }

    # Need two prescribed dose observations - mornign and evening
    drug_orders = DrugOrder.recommended_art_prescription(patient.current_weight)["Stavudine Lamivudine Nevirapine"]
    drug_orders.each{|drug_order|
      observation = Observation.new
      observation.patient = patient
      observation.encounter = art_visit_encounter
      observation.obs_datetime = visit_time
      observation.concept = Concept.find_by_name("Prescribed dose")
      # do logic to determine dose from weight
      observation.value_drug = drug_order.drug.id
      observation.value_text = drug_order.frequency
      observation.value_numeric = drug_order.units
      observation.save!
    }

    give_drugs = Encounter.new
    give_drugs.provider = User.current_user
    give_drugs.type = EncounterType.find_by_name("Give drugs")
    give_drugs.encounter_datetime = visit_time
    give_drugs.patient = patient
    give_drugs.save!

    order_type = OrderType.find_by_name("Give drugs")

    drug_orders.each{|drug_order|
      order = Order.new
      order.order_type = order_type
      order.orderer = User.current_user.id
      order.encounter = give_drugs
      order.save!
      drug_order.order = order
      drug_order.quantity = params[:number_of_months_supplied].to_i * 60
      drug_order.save!
    }

    redirect_to :action => "menu", :patient_id => patient_id
  end

  def menu
    patient_id = params[:patient_id]
    @patient = Patient.find(patient_id) rescue nil

    patient_arv_number = Patient.find(patient_id).arv_number unless patient_id.nil? rescue nil

    (1..5).to_a.each{|offset|
      next_patient_arv_number = patient_arv_number.gsub(/(\d+)/){($1.to_i+offset).to_s} unless patient_arv_number.nil?
      @next_patient = Patient.find_by_arvnumber(next_patient_arv_number) unless next_patient_arv_number.nil? rescue nil
      break unless @next_patient.nil?
    }


    render :layout => false
  end

  def select_patient
    patient_id = PatientIdentifier.find_by_identifier(params[:identifier]).patient.id rescue (redirect_to(:action => "menu") and return)
    redirect_to :action => "new_art_visit", :patient_id => patient_id
  end

end
