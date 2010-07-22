class StandardEncounterController < ApplicationController
  def new_art_visit
    session[:first_encounter_date] = nil
    @art_visit_type_id = EncounterType.find_by_name("ART Visit").id
    params[:patient_id] = session[:patient_id] unless session[:patient_id].blank?
    patient = Patient.find(params[:patient_id])
    encounter_dates = patient.encounters.sort{|a,b|b.encounter_datetime <=> a.encounter_datetime}
    session[:first_encounter_date] = encounter_dates.first.encounter_datetime
    session[:patient_id] = patient.id
    #render(:layout => "layouts/menu")
  end

  def add_outcome_died
    @patient = Patient.find(params[:patient_id])
    @patient.set_outcome("Dead",params[:date])
    redirect_to :action => "menu", :patient_id => params[:patient_id]
  end

  def create_art_visit
    patient = Patient.find(session[:patient_id])

    extended_questions = params[:extended_questions]
    weight = params[:weight]
    height = params[:height]
    optional_regimen = params[:optional_regimen]
    drug_remaining = params[:drug_remaining]
    symptoms = params[:symptoms]
    prescribe_cpt = params[:prescribe_cpt]
   
    year = params[:retrospective_patient_year]
    day = params[:retrospective_patient_day]
    month = params[:retrospective_patient_month]
    visit_type = params[:visit_type]
    pill_count = params[:pill_count].to_i rescue 0
    period = params[:time_period]
    session[:encounter_datetime] = "#{day}-#{month}-#{year}".to_time

    art_visit_encounter_type = EncounterType.find_by_name("ART Visit").id
    hiv_reception = EncounterType.find_by_name("HIV Reception").id
    weight_encounter = EncounterType.find_by_name("Height/Weight").id

    if extended_questions == "Yes" 
      regimen = Concept.find_by_name(optional_regimen).id
      concept_weight = Concept.find_by_name("Weight").id
      concept_height = Concept.find_by_name("Height").id
      concept_side_effects = Concept.find_by_name("Side effects").id
      concept_symptoms = Concept.find_by_name("Symptoms").id
      drug_id = Drug.find_by_name(drug_remaining).id 
      side_effect_ids =[]
      side_effect_names =[]
      symptoms.each{|symptom|
        next if symptom.blank?
        side_effect_ids << Concept.find_by_name(symptom).id
        side_effect_names << symptom
      }
    end

    quantity = 15 if period == "2 Weeks" ; quantity = 60 if period == "1 Month"
    quantity = 120 if period == "2 Months" ; quantity = 180 if period == "3 Months"
    quantity = 240 if period == "4 Months" ; quantity = 300 if period == "5 Months"
    quantity = 360 if period == "6 Months" 

    tb_status = Concept.find_by_name("TB status").id
    tb_ans = Concept.find_by_name("Unknown").id
    continue_art = Concept.find_by_name("Continue ART").id
    recommended_dosage = Concept.find_by_name("Prescribe recommended dosage").id
    cpt = Concept.find_by_name("Prescribe Cotrimoxazole (CPT)").id
    current_clinic = Concept.find_by_name("Continue treatment at current clinic").id
    prescribe_arvs = Concept.find_by_name("Prescribe ARVs this visit").id
    time_period = Concept.find_by_name("Prescription time period").id
    destination = Concept.find_by_name("Transfer out destination").id
    arv_regimen = Concept.find_by_name("ARV regimen").id
    show_adherence = Concept.find_by_name("Provider shown adherence data").id
    refer_to_clinician = Concept.find_by_name("Refer patient to clinician").id
    no = Concept.find_by_name("No").id
    yes = Concept.find_by_name("Yes").id
    if regimen.blank?
      regimen = Concept.find_by_name("Stavudine Lamivudine Nevirapine").id
      unless patient.previous_art_drug_orders(session[:encounter_datetime].to_date)
        # starter pack
        regimen = Concept.find_by_name("Stavudine Lamivudine + Stavudine Lamivudine Nevirapine").id
        drug_ids = [Drug.find_by_name("Stavudine 30 Lamivudine 150").id,
                    Drug.find_by_name("Stavudine 30 Lamivudine 150 Nevirapine 200").id]
        period = "2 weeks"
        quantity = 15
        pill_count = nil
      end
    end

    guardian_present = Concept.find_by_name("Guardian present").id
    patient_present = Concept.find_by_name("Patient present").id
    cpt_id = Drug.find_by_name("Cotrimoxazole 480").id

    if visit_type == "Patient"
      guardian_ans = no ; patient_ans = yes 
    elsif visit_type == "Guardian"
      guardian_ans = yes ; patient_ans = no 
    else
      guardian_ans = yes ; patient_ans = yes
    end

#........... Creating HIV Reception encounter
    observation = {"observation" =>{"select:#{guardian_present}" =>guardian_ans,"select:#{patient_present}" =>patient_ans}}
    result = create(hiv_reception,observation)
#..................................................

#........... Creating Height/Weight encounter
    observation = {"observation"=>{"number:#{concept_weight}" =>"#{weight}","number:#{concept_height}" => "#{height}"}}
    if not weight.blank? or not height.blank?
      result = create(weight_encounter,observation) 
    end  
#..................................................

    drug_id = Drug.find_by_name("Stavudine 30 Lamivudine 150 Nevirapine 200").id if drug_id.blank?
    if extended_questions == "Yes"
      patient_weight = weight unless weight.blank?
      if patient_weight.blank? and patient.child?
        patient_weight = patient.current_weight || 25
      elsif patient_weight.blank? and not patient.child?
        patient_weight = patient.current_weight || 50
      end

      recommended = DrugOrder.recommended_art_prescription(patient_weight.to_i)[optional_regimen]
      drug_ids = []
      recommended.each{|d| 
        next if d.drug_inventory_id.blank?
        drug_ids << d.drug_inventory_id
        drug_ids = drug_ids.uniq
      }

      if prescribe_cpt == "Yes"
        dispensed = {"#{cpt_id}"=>{"quantity"=>quantity, "packs"=>"1"}}
      end    
      
      dispensed = {} if dispensed.blank? 
      drug_ids.each{|id|
        if dispensed.blank?
          dispensed = {"#{id}" =>{"quantity"=>quantity, "packs"=>"1"}}
        else
          dispensed["#{id}"] = {"quantity"=>quantity, "packs"=>"1"}
        end    
      }
    elsif !patient.previous_art_drug_orders(session[:encounter_datetime]) # starter pack
      dispensed = {} if dispensed.blank? 
      drug_ids.each{|id|
        if dispensed.blank?
          dispensed = {"#{id}" =>{"quantity"=>quantity, "packs"=>"1"}}
        else
          dispensed["#{id}"] = {"quantity"=>quantity, "packs"=>"1"}
        end    
      }
    else
        dispensed = {"#{drug_id}" =>{"quantity"=>quantity, "packs"=>"1"}, "#{cpt_id}"=>{"quantity"=>quantity, "packs"=>"1"}}
    end    

    tablets = {"#{drug_id}" =>{"at_clinic" =>"#{pill_count}"}}

    if extended_questions == "No"
      observation = {"observation" =>{"select:#{tb_status}" => tb_ans ,"select:#{continue_art}" => yes,"select:#{recommended_dosage}" => yes, "select:#{cpt}" => yes, "select:#{current_clinic}" => yes,"select:#{prescribe_arvs}" => yes,"alpha:#{time_period}" => period,"location:#{destination}" => "","select:#{arv_regimen}" => regimen ,"select:#{show_adherence}" => yes,"select:#{refer_to_clinician}" => no}}
    else
      cpt_ans = no if prescribe_cpt == "No"
      cpt_ans = yes if prescribe_cpt == "Yes"
      observation = {"observation" =>{"select:#{tb_status}" => tb_ans ,"select:#{continue_art}" => yes,"select:#{recommended_dosage}" => yes, "select:#{cpt}" => cpt_ans, "select:#{current_clinic}" => yes,"select:#{prescribe_arvs}" => yes,"alpha:#{time_period}" => period,"location:#{destination}" => "","select:#{arv_regimen}" => regimen ,"select:#{show_adherence}" => yes,"select:#{refer_to_clinician}" => no,"select:#{concept_side_effects}"=>side_effect_names,"select:#{concept_symptoms}"=> side_effect_ids}}
    end

    result = create(art_visit_encounter_type,observation,tablets)
    redirect_to :controller => "drug_order",
        :action => "create",:dispensed => dispensed,:id => patient.id
  end

  def create(encounter_type,observation,tablets = nil)
    patient = Patient.find(session[:patient_id])
    Encounter.create(patient,observation,session[:encounter_datetime],session[:encounter_location],encounter_type,tablets)
  end

  def test_post
    require 'net/http'
    require 'uri'
    #url = URI.parse('http://127.0.0.1:3000/encounter/create')
    # build the params string
    post_args1 = { 'encounter_type_id' => hiv_reception,'observation' => reception_observation }
    # send the request
    #data = Net::HTTP.post(url, post_args1)
    #data = Net::HTTP.post_form(url, {'name' => 'soyapi'})
    Net::HTTP.start('127.0.0.1', 3000) do |http|
      data = http.post('/encounter/create', "name=soyapi&aaa=bbbb")
      raise data.to_yaml
    end
  end

  def create_art_short_visit
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
    params[:id] = session[:patient_id] unless session[:patient_id].blank?
    patient_id = params[:id] unless params[:id].blank?
    @patient = Patient.find(patient_id) rescue nil

    #patient_arv_number = Patient.find(patient_id).arv_number unless patient_id.nil? rescue nil

=begin
    (1..5).to_a.each{|offset|
      next_patient_arv_number = patient_arv_number.gsub(/(\d+)/){($1.to_i+offset).to_s} unless patient_arv_number.nil?
      @next_patient = Patient.find_by_arvnumber(next_patient_arv_number) unless next_patient_arv_number.nil? rescue nil
      break unless @next_patient.nil?
    }
=end

    render :layout => false
  end

  def select_patient
    patient_id = PatientIdentifier.find_by_identifier(params[:identifier]).patient.id rescue (redirect_to(:action => "menu") and return)
    redirect_to :action => "new_art_visit", :patient_id => patient_id
  end

  def add_visit
    patient = Patient.find(params[:patient_id])
    unless params[:edit_visit_date].blank?
      encounter_to_be_voided = Encounter.find(:all,
        :conditions => ["patient_id =? AND encounter_datetime >= ? AND encounter_datetime <= ?",
        patient.id,"#{params[:edit_visit_date]} 00:00:00","#{params[:edit_visit_date]} 23:59:59"]) rescue []
       
      encounter_to_be_voided.each do |encounter|  
        encounter.void!("Edited from the mastercard")
      end unless encounter_to_be_voided.blank?
    end
    session[:patient_id] = patient.id
    outcome = params[:outcome]
    tb_outcome = params[:tb_outcome]
    number_of_drugs_counted = params[:number_of_drugs_count].split(',') rescue nil
    counted_drug_ids = []
    pills_remaining = []
    number_of_drugs_counted.each do |drug_id|
      counted_drug_ids << drug_id
      pills_remaining << params["pillsremaining_#{drug_id}"].to_i rescue nil
    end
    drugs_given_to = params[:gave]
    weight = params[:weight]
    symptoms = params[:seffects]
    date = "#{params['date']['(1i)']}-#{params['date']['(2i)']}-#{params['date']['(3i)']}" if params[:edit_visit_date].blank?
    date = params[:edit_visit_date] unless params[:edit_visit_date].blank?
    regimen = params[:optional_regimen]
    height = params[:height]
    cpt = params[:cpt]
    cd4 = params[:cd4]
    period = params[:period]
    date = date.to_date rescue nil
    #render :text => "error on visit date #{date}" ; return if date.blank?
    session[:encounter_datetime] = Time.mktime(date.year,date.month,date.day,0,0,1)
    if date > Date.today then
      render :text => "Visit date is greater than current date - can not continue" ; return 
    end
    no = Concept.find_by_name("No").id
    yes = Concept.find_by_name("Yes").id

    if session[:patient_program] == "HIV"
      Location.current_location.location_id = Location.find_by_name(params[:selected_site]).id
    end

    #........... Creating HIV Reception encounter
    if drugs_given_to.to_s == "Patient"
      guardian_ans = no ; patient_ans = yes
    elsif drugs_given_to.to_s == "Guardian"
      guardian_ans = yes ; patient_ans = no
    else
      guardian_ans = yes ; patient_ans = yes 
    end
    hiv_reception = EncounterType.find_by_name("HIV Reception").id
    guardian_present = Concept.find_by_name("Guardian present").id
    patient_present = Concept.find_by_name("Patient present").id

    observation = {"observation" =>{"select:#{guardian_present}" =>guardian_ans,"select:#{patient_present}" =>patient_ans}}
    result = create(hiv_reception,observation) unless drugs_given_to.blank?
#..................................................

#........... Creating Height/Weight encounter
    weight_encounter = EncounterType.find_by_name("Height/Weight").id
    concept_weight = Concept.find_by_name("Weight").id
    concept_height = Concept.find_by_name("Height").id
    observation = {"observation"=>{"number:#{concept_weight}" =>"#{weight}","number:#{concept_height}" => "#{height}"}}
    if not weight.blank? or not height.blank?
      result = create(weight_encounter,observation) if patient_ans == yes
    end

#............. Creating art visit
    art_visit_encounter_type = EncounterType.find_by_name("ART Visit").id
    cpt_concept = Concept.find_by_name("Prescribe Cotrimoxazole (CPT)").id
    current_clinic = Concept.find_by_name("Continue treatment at current clinic").id
    arv_regimen = Concept.find_by_name("ARV regimen").id
    refer_to_clinician = Concept.find_by_name("Refer patient to clinician").id
    show_adherence = Concept.find_by_name("Provider shown adherence data").id
    time_period = Concept.find_by_name("Prescription time period").id
    destination = Concept.find_by_name("Transfer out destination").id
    prescribe_arvs = Concept.find_by_name("Prescribe ARVs this visit").id
    recommended_dosage = Concept.find_by_name("Prescribe recommended dosage").id
    continue_art = Concept.find_by_name("Continue ART").id
    tb_status_concept = Concept.find_by_name("TB status").id
    cpt_ans = no if cpt.blank?
    cpt_ans = yes unless cpt.blank?

    concept_side_effects = Concept.find_by_name("Side effects").id
    concept_symptoms = Concept.find_by_name("Symptoms").id
    #drug_id = Drug.find_by_name(drug_remaining).id 
    side_effect_ids =[]
    side_effect_names =[]
    symptoms.each{|symptom|
      next if symptom.blank?
      side_effect_ids << Concept.find_by_name(symptom).id
      side_effect_names << symptom
    } rescue nil

    observation = {"observation" =>{"select:#{tb_status_concept}" => tb_outcome ,
    "select:#{continue_art}" => yes,"select:#{recommended_dosage}" => yes,
    "select:#{cpt_concept}" => yes, "select:#{current_clinic}" => yes,"select:#{prescribe_arvs}" => yes,
    "alpha:#{time_period}" => period,"location:#{destination}" => "",
    "select:#{arv_regimen}" => regimen ,"select:#{show_adherence}" => yes,"select:#{refer_to_clinician}" => no,
    "select:#{concept_side_effects}"=>side_effect_names,"select:#{concept_symptoms}"=> side_effect_ids}}

    remaining_count = 0
    tablets = {}
    counted_drug_ids.each{|id|
      pills = pills_remaining[remaining_count] rescue 0
      tablets["#{id}"] = {"at_clinic" =>"#{pills}"}
      remaining_count+=1
    } rescue nil
    result = create(art_visit_encounter_type,observation,tablets)
    #........................

    #........................ Dispensing drugs
    patient_weight = weight unless weight.blank?
    if patient_weight.blank? and patient.child?
      patient_weight = patient.current_weight || 25
    elsif patient_weight.blank? and not patient.child?
      patient_weight = patient.current_weight || 50
    end

    if regimen
      optional_regimen = Concept.find(regimen).name
      recommended = DrugOrder.recommended_art_prescription(patient_weight.to_i)[optional_regimen]
      drug_ids = []
      recommended.each{|d|
        next if d.drug_inventory_id.blank?
        drug_ids << d.drug_inventory_id
        drug_ids = drug_ids.uniq
      }
    end

    unless cpt.blank? 
      cpt_id = Drug.find_by_name("Cotrimoxazole 480").id
      dispensed = {"#{cpt_id}"=>{"quantity"=>cpt, "packs"=>"1"}}
    end   

    quantity = 15 if period == "2 Weeks" ; quantity = 60 if period == "1 Month"
    quantity = 120 if period == "2 Months" ; quantity = 180 if period == "3 Months"
    quantity = 240 if period == "4 Months" ; quantity = 300 if period == "5 Months"
    quantity = 360 if period == "6 Months"
    dispensed = {} if dispensed.blank?
    drug_ids.each{|id|
      if dispensed.blank?
        dispensed = {"#{id}" =>{"quantity"=>quantity, "packs"=>"1"}}
      else
        dispensed["#{id}"] = {"quantity"=>quantity, "packs"=>"1"}
      end   
     } unless drug_ids.blank?

    if not outcome == "Alive" and not outcome.blank?
      case outcome
        when "TO(with note)"
          outcome = "Transfer Out(With Transfer Note)"
        when "TO(without note)"
          outcome = "Transfer Out(Without Transfer Note)"
        when "Died"
          outcome = "Died"
        when "Stop"
          outcome = "ART Stop"
      end
      redirect_to :controller => "patient",:action => "update_outcome",
        :dispensed => dispensed,:adding_visit => "true",
          :encounter_date => date,:id =>patient.id ,
          :outcome => outcome ,:method => :post ,:selected_site => :params[:selected_site] ; return
    end  

    redirect_to :controller => "drug_order",:action => "create",
      :dispensed => dispensed,:adding_visit => "true" ,:id => patient.id,
      :selected_site => params[:selected_site] ; return
  end

end
