class EncounterController < ApplicationController

  def summary
    @encounter = Encounter.find(params[:id])
  
    if @encounter.nil?
      redirect_to(:controller => "patient", :action => "menu") and return
    end
  end

  def scan
    barcode = params[:barcode]
    barcode_cleaned = barcode.gsub(/(-| |\$)/,"") #remove spaces and dashes
    arv_number = barcode_cleaned
    arv_number_cleaned = arv_number.match(/[a-z]+/i)[0] + arv_number.match(/\d+/)[0] if arv_number.match(/[a-z]+/i) and arv_number.match(/\d+/)
    arv_number_cleaned = barcode_cleaned if !barcode_cleaned.match(/[a-z]+/i) and barcode_cleaned.match(/\d+/) and arv_number_cleaned.blank?

    @patient = PatientIdentifier.find(:first, :conditions => ["identifier = ? OR identifier = ? OR identifier = ?", barcode, barcode_cleaned, arv_number]).patient rescue nil

    if @patient.blank? and arv_number_cleaned and !barcode.match(/-/)
     arv_code = arv_number_cleaned.match(/[a-zA-Z]+/).to_s rescue nil
     number= arv_number_cleaned.match(/\d+/).to_s rescue nil
     if arv_code.blank? 
      cleaned_arv_number= Location.current_arv_code + number.to_i.to_s unless number.blank? 
     else
      cleaned_arv_number = arv_code.upcase + number.to_i.to_s if !number.blank?  
     end
     @patient = Patient.find_by_arvnumber(cleaned_arv_number) unless cleaned_arv_number.blank?
    end
 
    if @patient.blank?
     if barcode_cleaned.match(/P/i)     
      valid_msg = Patient.validates_national_id(barcode_cleaned)
      flash_msg = "#{barcode_cleaned} or #{barcode}" if barcode.match(/(-| )/)    
      flash_msg = "#{barcode}" unless barcode.match(/(-| )/)    
      flash[:error] = "Could not find a patient with national id: #{flash_msg}" if valid_msg == "valid id"
      flash[:error] = "Could not find a patient with national id: #{flash_msg} ,#{valid_msg}" if valid_msg == "id should have 13 characters"
      flash[:error] = "Could not find a patient with national id: #{flash_msg}, scanning error!! scan again or find patient by name" if valid_msg == "check digit is wrong"
      flash[:error] = "Could not find a patient with national id: #{flash_msg} , id is invalid!!" if valid_msg == "invalid id"
     elsif !barcode_cleaned.match(/P/i) and !barcode.match(/-/)
      cleaned_arv_number=arv_number if cleaned_arv_number.blank?
      flash[:error] = "Could not find Patient with arv number: #{cleaned_arv_number}"
     else
      flash[:error] = "Could not find Patient with id: #{barcode}"
     end

     redirect_to(:controller => "patient", :action => "menu", :no_auto_load_forms => true ) and return
    end  
    
    encounter = Encounter.new()
    encounter.provider_id = User.current_user.id
    encounter.patient_id = @patient.id
    encounter.encounter_type = EncounterType.find_by_name("Barcode scan").id
    encounter.encounter_datetime = Time.now
    encounter.save or flash[:error] = "Could not save scan encounter"
    redirect_to :controller => "patient", :action => "set_patient", :id => @patient.id
  end
  
  def create
    patient = Patient.find(session[:patient_id])
 
    encounter = new_encounter_from_encounter_type_id(params[:encounter_type_id])

    if patient.child? and encounter.name == 'HIV Staging'
      #We want to determine severe / moderate wasting based on today's ht/wt rather than depending on the user selection of such indicators
      yes_concept_id = Concept.find_by_name("Yes").id
      no_concept_id = Concept.find_by_name("No").id
      child_severe_wasting_concept = Concept.find_by_name('Severe unexplained wasting / malnutrition not responding to treatment(weight-for-height/ -age less than 70% or MUAC less than 11cm or oedema)')
      child_moderate_wasting_concept = Concept.find_by_name('Moderate unexplained wasting / malnutrition not responding to treatment (weight-for-height/ -age 70-79% or MUAC 11-12cm)')
      if patient.weight_for_height && patient.weight_for_age
        if (patient.weight_for_height >= 70 && patient.weight_for_height <= 79) || (patient.weight_for_age >= 70 && patient.weight_for_age <= 79)
          params[:observation]["select:#{child_moderate_wasting_concept.id}"] = yes_concept_id
        else
          params[:observation]["select:#{child_moderate_wasting_concept.id}"] = no_concept_id
        end
        if patient.weight_for_height < 70 || patient.weight_for_age < 70
          params[:observation]["select:#{child_severe_wasting_concept.id}"] = yes_concept_id
        else
          params[:observation]["select:#{child_severe_wasting_concept.id}"] = no_concept_id
        end
      end
    end

    encounter.parse_observations(params) # parse params and create observations from them
    encounter.save

    patient.arv_number= "#{Location.current_arv_code} #{params[:arv_number].to_i}" if params[:arv_number]

    @menu_params = ""

    #case encounter.type.name
    case encounter.name
      when "HIV Staging"
        staging(encounter)
      when "ART Visit"
        art_followup(encounter,patient)
    end

    encounter.patient.reset_outcomes if encounter.name =~ /ART Visit|Give drugs|Update outcome/
    redirect_to "/patient/menu?" + @menu_params
  end

  def staging(encounter)
    retrospective_staging(encounter)
    determine_hiv_wasting_syndrome(encounter) if not Patient.find(session[:patient_id]).child? #we no longer need to determine hiv wasting for children
  end

  def retrospective_staging(encounter)
    # Get all of the selected conditions into one array
    presumed_hiv_conditions = params["presumed_hiv_disease_conditions"].flatten.compact rescue nil #conditions for kids under 17 mons with rapid test are collected here
    conditions = [1,2,3,4].collect{|stage_number| params["stage#{stage_number}"]}.flatten.compact
    conditions += presumed_hiv_conditions unless presumed_hiv_conditions.blank?
    yes = Concept.find_by_name("Yes")
    conditions.each{|concept_id|
      observation = encounter.add_observation(concept_id)
      observation.value_coded = yes.id
      observation.save
    }
  end

  def art_followup(encounter,patient)
		clinician_referral_id = Concept.find_by_name("Refer patient to clinician").id
		refer_to_clinician = params["observation"]["select:#{clinician_referral_id}"]
		@menu_params = "no_auto_load_forms=true" if refer_to_clinician.to_i == Concept.find_by_name("Yes").id unless refer_to_clinician.nil?
    # tablets
    concept_brought_to_clinic = Concept.find_by_name("Whole tablets remaining and brought to clinic")
    concept_not_brought_to_clinic = Concept.find_by_name("Whole tablets remaining but not brought to clinic")
    params["tablets"].each{|drug_id, location_amount|
      
      location_amount.each{|location,amount|
        if location == "at_clinic"
          observation = encounter.add_observation(concept_brought_to_clinic.id)
        else
          observation = encounter.add_observation(concept_not_brought_to_clinic.id)
        end
        observation.value_drug = drug_id
        if amount == 'Unknown'
          observation.value_numeric = nil
          observation.value_coded = Concept.find_by_name('Unknown').id
        else
          observation.value_numeric = amount
        end
        observation.save
      }
    } unless params["tablets"].nil?
    
    prescribed_dose = Concept.find_by_name("Prescribed dose")



   #_____________________________________________________________

   yes_concept_id = Concept.find(:first,:conditions => ["name=?","Yes"]).concept_id
   drug_concept_id = Concept.find(:first,:conditions => ["name=?","ARV regimen"]).concept_id
   recommended_dosage = Concept.find(:first,:conditions => ["name=?","Prescribe recommended dosage"]).concept_id
   prescribe_drugs=Hash.new()

   if !params["observation"]["select:#{drug_concept_id}"].blank? and  params["observation"]["select:#{drug_concept_id}"] != "Other"
     drug_concept_name = Concept.find(:first,:conditions => ["concept_id=?", params["observation"]["select:#{drug_concept_id}"].to_i]).name
     prescription = DrugOrder.recommended_art_prescription(patient.current_weight)[drug_concept_name]
     prescription.each{|recommended_presc|
       drug = Drug.find(recommended_presc.drug_inventory_id)
       prescribe_drugs[drug.name] = {"Morning" => "None", "Noon" => "None", "Evening" => "None", "Night" => "None"} if prescribe_drugs[drug.name].blank?
       prescribe_drugs[drug.name][recommended_presc.frequency] = recommended_presc.units.to_s 
     }
   else
        Drug.find(:all,:conditions =>["concept_id IS NOT NULL"]).each{|drug|
          ["Morning","Noon","Evening","Night"].each{|time|
            if !params["#{drug.name}_#{time}"].blank?  
              prescribe_drugs[drug.name] = {"Morning" => "None", "Noon" => "None", "Evening" => "None", "Night" => "None"} if prescribe_drugs[drug.name].blank?
              prescribe_drugs[drug.name][time] = params["#{drug.name}_#{time}"] 
            elsif params["#{drug.name}"] == "Yes"
              prescribe_drugs[drug.name] = {"Morning" => "None", "Noon" => "None", "Evening" => "None", "Night" => "None"} if prescribe_drugs[drug.name].blank?
              prescription = DrugOrder.recommended_art_prescription(patient.current_weight)[drug.concept.name]
              prescription.each{|recommended_presc|
                prescribe_drugs[drug.name][recommended_presc.frequency] = recommended_presc.units.to_s 
              }
            end  
      }
     }
   end
      
      
   prescribe_cpt = Concept.find(:first,:conditions => ["name=?","Prescribe Cotrimoxazole (CPT)"]).concept_id
   if params["observation"]["select:#{prescribe_cpt}"] == yes_concept_id.to_s
     prescribe_drugs["Cotrimoxazole 480"] = {"Morning" => "1.0", "Noon" => "None", "Evening" => "1.0", "Night" => "None"}
   end 
       
#______________________________________________________________________
    prescribe_drugs.each{|drug_name, frequency_quantity|
      drug = Drug.find_by_name(drug_name)
      raise "Can't find #{drug_name} in drug table" if drug.nil?
      frequency_quantity.each{|frequency, quantity|
        next if frequency.blank? || quantity.blank?
        observation = encounter.add_observation(prescribed_dose.concept_id)
        observation.drug = drug
        observation.value_numeric = eval("1.0*" + validate_quantity(quantity)) rescue 0.0
        observation.value_text = frequency
        observation.save
      }
    } unless prescribe_drugs.blank?

      #DrugOrder.recommended_art_prescription(patient.current_weight)[regimen_string].each{|drug_order|
  end

  def validate_quantity(quantity)
    return "0" if quantity.to_s == "None"
    return quantity.to_s unless quantity.to_s.include?("/")
    case quantity.gsub("(","").gsub(")","").strip
      when "1/4"
        return "0.25" 
      when "1/5"
        return "0.5" 
      when "3/4"
        return "0.75" 
      when "1 1/4"
        return "1.25" 
      when "1 1/2"
        return "1.5" 
      when "1 3/4"
        return "1.75" 
      when "1/3"
        return "0.3" 
    end 
  end

  def get_arv_national_id
    return "TMP100" #This line creates a duplicate primary key for patient_identifier
    location_description = Location.current_location.health_center.description
    if location_description =~ /arv code:(\w\w\w)/
      arv_site_code = $1 # Get the arc code from the description field in the location
    else
      raise "Health center location description (location table, description field) needs a three digit code to use for arv site code: #{location_description}" 
    end

    
    # find the last identifier for this location, chop off the location prefex, cast it as signed int so it can be sorted
    search_result = PatientIdentifier.find_by_sql(["SELECT CAST(SUBSTRING(identifier,4) AS SIGNED) as number_part_of_id FROM patient_identifier WHERE identifier_type = ? AND LEFT(identifier,3) = ? ORDER BY number_part_of_id DESC LIMIT 1;",PatientIdentifierType.find_by_name("Arv national id").id, arv_site_code])[0]
    last_number = search_result.number_part_of_id unless search_result.nil?
    last_number ||= 0

    arv_site_code + (last_number.to_i + 1).to_s.rjust(2,'0')
  end


  def determine_hiv_wasting_syndrome(encounter)
    # HIV wasting syndrome (weight loss > 10% of body weight and either chronic fever or diarrhoea in the absence of concurrent illness)
    # Concepts needed for this section
    hiv_wasting_syndrome_concept = Concept.find_by_name("HIV wasting syndrome (severe weight loss + persistent fever or severe loss + chronic diarrhoea)")
# If there is already an hiv_wasting_syndrom observation then there is not need to run this code
    return unless encounter.observations.find_by_concept_id(hiv_wasting_syndrome_concept.id).empty?
    severe_weightloss_concept = Concept.find_by_name "Severe weight loss >10% and/or BMI <18.5kg/m(squared), unexplained"
    chronic_fever_concept = Concept.find_by_name "Fever, persistent unexplained (intermittent or constant, > 1 month)"
    chronic_diarrhoea_concept = Concept.find_by_name "Diarrhoea, chronic (>1 month) unexplained"
    yes_concept = Concept.find_by_name "Yes"


    has_severe_weightloss = false
    has_chronic_fever = false
    has_chronic_diarrhoea = false
    encounter.observations.each{|observation|
      has_severe_weightloss = true if observation.concept_id == severe_weightloss_concept.id and observation.value_coded == yes_concept.id
      has_chronic_fever = true if observation.concept_id == chronic_fever_concept.id and observation.value_coded == yes_concept.id
      has_chronic_diarrhoea = true if observation.concept_id == chronic_diarrhoea_concept.id and observation.value_coded == yes_concept.id
    }
    
    # calc hiv wasting syndrome
    hiv_wasting_syndrome_observation = encounter.add_observation(Concept.find_by_name("HIV wasting syndrome (severe weight loss + persistent fever or severe loss + chronic diarrhoea)").id)
    if has_severe_weightloss and (has_chronic_fever or has_chronic_diarrhoea)
      hiv_wasting_syndrome_observation.value_coded = yes_concept.id
    else
      hiv_wasting_syndrome_observation.value_coded = Concept.find_by_name("No").id
    end
    hiv_wasting_syndrome_observation.save

  end

  def view
    encounter_id = params[:id]
    @encounter = Encounter.find(encounter_id)
    @observations = @encounter.observations unless @encounter.nil?
    @hide_header = params[:hide_header]
    render :layout => false
  end

  def void
    # don't void for no reason
    return if params[:id].blank? or params[:void].blank? or 
              params[:void][:reason].blank?

    encounter_id = params[:id]
    void_reason = params[:void][:reason]

    encounter = Encounter.find(encounter_id)
    encounter.void!(void_reason)

    redirect_to :controller => "patient", :action => "encounters"
  end

#  def staging_summary
#    @encounter = Encounter.find(params[:id])
#    if @encounter.nil?
#      flash[:error] = "Could not find staging encounter"
#      redirect_to(:controller => "patient", :action => "menu") and return
#    end
#
#    @who_stage = @encounter.observations.find_by_concept_name("WHO stage").first.result_to_string
#    @reason_antiretrovirals_started = @encounter.observations.find_by_concept_name("Reason antiretrovirals started").first.result_to_string
#    @hiv_wasting_syndrome = @encounter.observations.find_by_concept_name("HIV wasting syndrome (weight loss > 10% of body weight and either chronic fever or diarrhoea in the absence of concurrent illness)").first.result_to_string
#  end
#  

#  def art_staging
#      determine_reason_for_starting(session[:encounter],who_stage_number)
#
#      arv_national_id = PatientIdentifier.new
#      arv_national_id.identifier_type = PatientIdentifierType.find_by_name("Arv national id").id
#      arv_national_id.identifier = get_arv_national_id()
#      arv_national_id.patient_id = session[:patient_id]
#      arv_national_id.save
#
#      redirect_to(:controller => "encounter", :action => "staging_summary", :id => session[:encounter].id) and return
#  end
#
#
#  def determine_reason_for_starting(encounter,who_stage)
#    # calc reason for starting
#    #
#    # TODO handle cd4 percentage for children
#    # 
#    # If stage 3 or 4, that is the reason. Otherwise must have CD4 < 250 or lymphocyte count < 1200
#    reason_for_starting_observation = new_observation(Concept.find_by_name("Reason antiretrovirals started").id,encounter)
#
#    patient = Patient.find(session[:patient_id])
#
#    if(who_stage >= 3)
#      adult_or_peds = patient.child? ? "peds" : "adult"
#      reason_for_starting_observation.value_coded = Concept.find_by_name("WHO stage #{who_stage} #{adult_or_peds}").id
#    else
## check for lymphocyte observation below 1200
#      if patient.child?
#        # table from ART guidelines, threshold defined as severe by Tony Harries after inquiry from Mike to Mindy
#        # For example: <1 year requires less than 4000 to be eligible
#        {1=>4000, 3=>3000, 5=>2500, 15=>2000}
#        low_lymphocyte_count = !encounter.patient.observations.find(:first, :conditions => ["value_numeric < ? AND concept_id = ?",1200, Concept.find_by_name("Lymphocyte count").id]).nil?
#      else
#        low_lymphocyte_count = !encounter.patient.observations.find(:first, :conditions => ["value_numeric < ? AND concept_id = ?",1200, Concept.find_by_name("Lymphocyte count").id]).nil?
#      end
#
#      if low_lymphocyte_count and who_stage >= 2
#        reason_for_starting_observation.value_coded = Concept.find_by_name("Lymphocyte count below threshold with WHO stage 2").id
#      else
## check for CD4 observation below 250
#        low_cd4_count = !encounter.patient.observations.find(:first, :conditions => ["value_numeric < ? AND concept_id = ?",250, Concept.find_by_name("CD4 count").id]).nil?
#        if low_cd4_count
#          reason_for_starting_observation.value_coded = Concept.find_by_name("CD4 count < 250").id
#        end
#      end
#    end
#    if reason_for_starting_observation.value_coded.nil?
#      flash[:error] = "Patient is not eligible to start ARVs. Must have WHO Stage > 3 (currently: #{who_stage}) or have a CD4 count below 250 or a lymphocyte count below 1200 with stage 2"
#    else
#      reason_for_starting_observation.save
#    end
#  end 
  

end
