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
    encounter = new_encounter_from_encounter_type_id(params[:encounter_type_id])
    encounter.parse_observations(params) # parse params and create observations from them
    encounter.save

    Patient.find(session[:patient_id]).arv_number= "#{Location.current_arv_code} #{params[:arv_number].to_i}" if params[:arv_number]

    @menu_params = ""

    #case encounter.type.name
    case encounter.name
      when "HIV Staging"
        staging(encounter)
      when "ART Visit"
        art_followup(encounter)
    end

		redirect_to "/patient/menu?" + @menu_params
  end

  def staging(encounter)
    retrospective_staging(encounter)
    determine_hiv_wasting_syndrome(encounter)
  end

  def retrospective_staging(encounter)
    # Get all of the selected conditions into one array
    conditions = [1,2,3,4].collect{|stage_number| params["stage#{stage_number}"]}.flatten.compact
    yes = Concept.find_by_name("Yes")
    conditions.each{|concept_id|
      observation = encounter.add_observation(concept_id)
      observation.value_coded = yes.id
      observation.save
    }
  end

  def art_followup(encounter)
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
        observation.value_numeric = amount
        observation.save
      }
    } unless params["tablets"].nil?
    
    prescribed_dose = Concept.find_by_name("Prescribed dose")
    
    params["dose"].each{|drug_name, frequency_quantity|
      next if drug_name.match(/^\d+$/) #blank does information is just numbers so skip these
      drug = Drug.find_by_name(drug_name)
      raise "Can't find #{drug_name} in drug table" if drug.nil?
      frequency_quantity.each{|frequency, quantity|
        observation = encounter.add_observation(prescribed_dose.concept_id)
        observation.drug = drug
        observation.value_numeric = eval("1.0*" + quantity)
        observation.value_text = frequency
        observation.save
      }
    } unless params["dose"].nil?

    recommended_dosage_concept = Concept.find_by_name("Prescribe recommended dosage")
    prescribe_cotrimoxazole_concept = Concept.find_by_name("Prescribe Cotrimoxazole (CPT)")
    yes_concept = Concept.find_by_name("Yes")
    regimen_concept = Concept.find_by_name("ARV regimen")
    patient = Patient.find(session[:patient_id])
    if params["observation"]["select:#{recommended_dosage_concept.id}"] == yes_concept.id.to_s
      #lookup recommended dosage for regimen and save it as above
      regimen = params["observation"]["select:#{regimen_concept.id}"]
      regimen_string = Concept.find(regimen).name

      DrugOrder.recommended_art_prescription(patient.current_weight)[regimen_string].each{|drug_order|
        observation = encounter.add_observation(prescribed_dose.concept_id)
        observation.drug = drug_order.drug
        observation.value_numeric = drug_order.units
        observation.value_text = drug_order.frequency
        observation.save
      }
    else
      # Doses are handled above just need to handle stavudine dosage change
      stavudine_dosage = params["observation"]["alpha:#{Concept.find_by_name('Stavudine Dosage').id}"]
      # .blank? catches both nil? and "" or empty?
      if not stavudine_dosage.blank?
        #lookup recommended dosage for regimen and save it as above
        regimen = params["observation"]["select:#{regimen_concept.id}"]
        regimen_string = Concept.find(regimen).name

        DrugOrder.recommended_art_prescription(patient.current_weight)[regimen_string].each{|drug_order|
          observation = encounter.add_observation(prescribed_dose.concept_id)
          if drug_order.drug.name.match(/Stavudine/)
            # Take the recommended drug name and replace the stavudine dosage with the selected amoun
            drug_name_with_new_dosage = drug_order.drug.name.sub(/Stavudine \d+/,"Stavudine #{stavudine_dosage.match(/\d+/).to_s}")
            drug = Drug.find_by_name(drug_name_with_new_dosage)
            raise "Could not find drug: #{drug_name_with_new_dosage} in drug table" if drug.nil?
            observation.drug = drug
            observation.value_numeric = drug_order.units
            observation.value_text = drug_order.frequency
            observation.save
          end
        }
      end
    end
    # create transfer out letter TODO

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
    hiv_wasting_syndrome_concept = Concept.find_by_name("HIV wasting syndrome (weight loss more than 10% of body weight and either chronic fever or diarrhoea in the absence of concurrent illness)")
# If there is already an hiv_wasting_syndrom observation then there is not need to run this code
    return unless encounter.observations.find_by_concept_id(hiv_wasting_syndrome_concept.id).empty?
    severe_weightloss_concept = Concept.find_by_name "Unintentional weight loss: more than 10% of body weight in the absence of concurrent illness"
    chronic_fever_concept = Concept.find_by_name "Prolonged fever (intermittent or constant) for more than 1 month"
    chronic_diarrhoea_concept = Concept.find_by_name "Chronic diarrhoea for more than 1 month"
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
    hiv_wasting_syndrome_observation = encounter.add_observation(Concept.find_by_name("HIV wasting syndrome (weight loss more than 10% of body weight and either chronic fever or diarrhoea in the absence of concurrent illness)").id)
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
