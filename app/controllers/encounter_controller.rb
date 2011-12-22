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

    patients = PatientIdentifier.find(:all, :conditions => ["voided = 0 AND (identifier = ? OR identifier = ? OR identifier = ?)", barcode, barcode_cleaned, arv_number])

    unless patients.blank?
      if patients.length > 1
        redirect_to :controller => "patient" ,:action => "reassign_national_id" ,:identifier => barcode_cleaned and return
      elsif patients.length == 1
        @patient = patients.last.patient
      end
    end

    if session[:patient_program].blank?
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
    else
      @patient = PatientIdentifier.find(:first, :conditions => ["voided = 0 AND identifier = ? AND identifier_type = ?",
        barcode_cleaned,PatientIdentifierType.find_by_name("National id").id]).patient rescue nil if @patient.blank?
      if @patient.blank? and session[:patient_program]=="HIV"
        str_passed = "#{barcode_cleaned.match(/[a-z]+/i)[0] rescue Location.current_arv_code} #{barcode_cleaned.match(/\d+/)[0] rescue nil}"
        @patient = PatientIdentifier.find(:first, :conditions => ["voided = 0 AND identifier = ? AND identifier_type = ?",
          str_passed,PatientIdentifierType.find_by_name("Arv national id").id]).patient rescue nil
      elsif @patient.blank? and session[:patient_program] =="TB"
        str_passed = "#{barcode_cleaned.match(/[a-z]+/i)[0].upcase rescue 'ZA'} #{barcode_cleaned.match(/\d+/)[0] rescue nil}"
        @patient = PatientIdentifier.find(:first, :conditions => ["voided = 0 AND identifier = ? AND identifier_type = ?",
          str_passed,PatientIdentifierType.find_by_name("TB treatment ID").id]).patient rescue nil
      end
    end
 
    if @patient.blank?

     if session[:patient_program].blank?
      new_national_id = PatientNationalId.find(:first, :conditions => ["assigned = 1 AND national_id = ?",barcode_cleaned])
      unless new_national_id.blank?
        session[:patient_id] = nil ; session[:encounter_datetime] = nil
        redirect_to :controller => "patient",:action => "new",:new_national_id => barcode_cleaned
        return
      end
     end


     if (barcode_cleaned.length == 6 and session[:patient_program].blank?)
       flash[:error] = "Could not find a patient with national id: #{barcode_cleaned}" 
       redirect_to(:controller => "patient", 
                   :action => "menu", 
                   :no_auto_load_forms => true, 
                   :existing_num => barcode_cleaned) and return
     end

     if barcode_cleaned.match(/P/i)     
      valid_msg = Patient.validates_national_id(barcode_cleaned)
      flash_msg = "#{barcode_cleaned} or #{barcode}" if barcode.match(/(-| )/)    
      flash_msg = "#{barcode}" unless barcode.match(/(-| )/)    
      flash[:error] = "Could not find a patient with national id: #{flash_msg}" if valid_msg == "valid id"
      flash[:error] = "Could not find a patient with national id: #{flash_msg} ,#{valid_msg}" if valid_msg == "id should have 13 characters"
      flash[:error] = "Could not find a patient with national id: #{flash_msg}, scanning error!! scan again or find patient by name" if valid_msg == "check digit is wrong"
      flash[:error] = "Could not find a patient with national id: #{flash_msg} , id is invalid!!" if valid_msg == "invalid id"
      if valid_msg == "valid id"
        @location_name = Location.find(barcode_cleaned[2..4]).name
      end  
     elsif !barcode_cleaned.match(/P/i) and !barcode.match(/-/)
      cleaned_arv_number=arv_number if cleaned_arv_number.blank?
      flash[:error] = "Could not find Patient with arv number: #{cleaned_arv_number}"
     else
      flash[:error] = "Could not find Patient with id: #{barcode}"
     end
   
     if params[:retrospective_data_entry] == "true"
       redirect_to :controller => "patient",:action =>"retrospective_data_entry_menu" ; return 
     else  
      redirect_to(:controller => "patient", :action => "menu", :no_auto_load_forms => true, :location_name => @location_name, :existing_num => barcode_cleaned) and return
     end
    end  
    
    if params[:retrospective_data_entry] == "true"
      if session[:patient_program] == "TB"
        redirect_to :controller => "patient",
          :action =>"tb_card", :id => @patient.id,:visit_added => "true" ; return 
      else  
        redirect_to :controller => "patient",
          :action =>"retrospective_data_entry", :id => @patient.id,:visit_added => "true" ; return 
      end
    end
=begin
    encounter = Encounter.new()
    encounter.provider_id = User.current_user.id
    encounter.patient_id = @patient.id
    encounter.encounter_type = EncounterType.find_by_name("Barcode scan").id
    encounter.encounter_datetime = Time.now
    encounter.save or flash[:error] = "Could not save scan encounter"
=end
    unless params[:merge].blank?
      if params[:first_patient] and not params[:second_patient]
        div = "right_div"
      elsif not params[:first_patient] and params[:second_patient]
        div = "left_div"
      else
        div = "left_div"  
      end  
      session[:merging_patients] = "#{div};#{params[:first_patient]};#{params[:second_patient]}" 
    end
    redirect_to :controller => "patient", :action => "set_patient", :id => @patient.id
  end
  
  def create
    patient = Patient.find(session[:patient_id])
    encounter_datetime = session[:encounter_datetime] ; location_id = session[:encounter_location]
    encounter_type = params[:encounter_type_id] 
    result = Encounter.create(patient,params,encounter_datetime,location_id,encounter_type,params[:tablets])
    redirect_to result
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

  def view
    encounter_id = params[:id]
    @encounter = Encounter.find(encounter_id)
    @observations = @encounter.observations unless @encounter.blank?
    @hide_header = params[:hide_header]
    render :layout => false
  end

  def void
    # don't void for no reason
    if session[:patient_program] == "HIV"
      if params[:id].blank? or params[:void].blank? or 
              params[:void][:reason].blank?
        @patient_id = params[:patient_id]       
        @encounter_id = params[:id]
        @encounter_date = params[:date]
        render :layout => false and return
      end
    end        

    return if params[:id].blank? or params[:void].blank? or 
              params[:void][:reason].blank?

    encounter_id = params[:id]
    void_reason = params[:void][:reason]

    encounter = Encounter.find(encounter_id)
    encounter.void!(void_reason)

    if session[:patient_program] == "HIV"
      redirect_to :controller => "patient", :action => "encounters",
        :id => params[:patient_id],:date => params[:encounter_date] and return
    end  
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
