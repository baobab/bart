require 'enumerator'

class PatientController < ApplicationController

  verify :method => :post, :only => [ :destroy],
         :redirect_to => { :action => :list }
    
  # Renders the patient menu as the default action
  def index
    redirect_to :action => 'menu'
  end

  # Renders a list of patients that have had visits on a particular date (in order)
  #
  # Session:
  # [<tt>:encounter_datetime</tt>] The date that is supplied will be put into the session as :encounter_datetime
  #
  # Valid params:
  # [<tt>:id</tt>] The date that is used for generating the list, or today by default

  # Renders the encounters for a patient. This method is coupled with (and only
  # used by) list_by_visit_date. The only call is in the view for list_by_visit_date.rhtml
  # where the patient_id is added as a param.
  #
  # Session:
  # [<tt>:patient_id</tt>] The patient identifier used for looking up encounters. Optional if param is included.
  #
  # Valid params:
  # [<tt>:patient_id</tt>] The patient identifier used for looking up encounters. Optional if param is included.
  def set_and_show_encounters
    patient_id = session[:patient_id] if session[:patient_id]
    patient_id = params[:id].to_i unless params[:id].blank?
    
    # redirect to patient search if patient_id.nil?
    #
    session[:patient_id] = patient_id
    redirect_to :action => "encounters"
  end

  # REFACTOR: This method has been marked for refactoring and should be moved into the model
  # REFACTOR: Patient.title method should be added which checks the gender 
  # Return an HL7 document for the patient specified in the params +id+.
  #
  # Valid params:
  # [<tt>:id</tt>] The id of the patient used when creating the HL7 data
  def hl7
    @patient = Patient.find(params[:id])
    @patient_title = "Mr"
    @patient_title = "Ms." if @patient.gender == "Female"
    @patient_guardian_id = @patient.art_guardian.patient_id unless @patient.art_guardian.blank?
    @patient_guardian = @patient.art_guardian.name unless @patient.art_guardian.blank?
    @district_of_initiation = Location.find(@patient.district_of_initiation.value_numeric) rescue nil# BUG first is not a method
    @district_time_of_observation = @patient.district_of_initiation.obs_datetime rescue nil
    unless  @patient.first_cd4_count.blank?
      @first_cd4 = @patient.first_cd4_count.value_numeric
      @cd4_observation_date = @patient.first_cd4_count.obs_datetime
    else
      @first_cd4 =""
      @cd4_observation_date =""
    end
    
    arv_number = @patient.hl7_arv_number
    unless arv_number.nil?
     @last_arv_number = arv_number.identifier
     @arv_obs_date    = arv_number.date_created 
    else
     @last_arv_number = ""
     @arv_obs_date    = "" 
    end	    
    render :layout => false
  end

  def new
    if params[:patient_id].nil?
      @patient = Patient.new
    else
      @patient_id = params[:patient_id]
    end    
    @patient_first_name = params[:name]
    @patient_surname = params[:family_name]
    @patient_other_name = params[:other_name]
    @patient_sex = params[:patient_gender]
    @patient_birthyear = params[:patient_birth_year]
    @patient_birthmonth = params[:patient_birth_month]
    @patient_birthdate = params[:patient_birth_date]
    @residence = params[:residence]
    @birth_place = params[:birth_place]

    # TEST NEEDED 
    @patient_birthyear = @patient_birthyear['birthyear(1i)'].to_i rescue nil #unless @patient_birthyear.nil?
    @patient_birthmonth = @patient_birthmonth['birthmonth(2i)'].to_i rescue nil #unless @patient_birthmonth.nil? 
    @patient_birthdate = @patient_birthdate['birthday(3i)'].to_i rescue nil #unless @patient_birthdate.nil?

    @patient_or_guardian = session[:patient_id].nil? ? "patient" : "guardian" #if the patient session is nil then assign "patient" to the variable @patient_or_guardian else assign guardian.
    @needs_date_picker = true

    @new_national_id = params[:new_national_id]
  end

  # REFACTOR: This method should probably be moved to a private as it is not called
  # REFACTOR: from outside the controller. It could even be a before_filter for
  # REFACTOR: specific methods. It is also possible that this could be a helper
  # REFACTOR: or Date specific method which returns an array
  # Adjust the year, month, and day params based on unknown options
  #
  # Returns: 
  # Whether or not the resulting date is an estimate  
  def set_date
    estimate = false
    #unless session[:outcome].blank? #adjust date for patient outcome 
      if params[:patient_month] == "Unknown" or params[:patient_month] == "unknown"
         params[:patient_month] = "July"
         params[:patient_day] = "1"
         estimate = true
      end
                                 
      if params[:patient_day] == "Unknown" or params[:patient_day] == "unknown"
         params[:patient_day] = "15" 
         estimate = true 
      end 
      
      if params[:patient_age][:age_estimate] !="" and  (params[:patient_year] == "Unknown" or params[:patient_year] == "unknown")
        patient_estimated_birthyear = Time.now().year - params[:patient_age][:age_estimate].to_i
      end
      
      if patient_estimated_birthyear != "" and (params[:patient_year] == "Unknown" or params[:patient_year] == "unknown")
        params[:patient_year] = patient_estimated_birthyear
        params[:patient_month] = "July"
        params[:patient_day] = "1"
        estimate = true
      end    
      return estimate
=begin   
    else    
      if params[:patient_month] == "Unknown" or params[:patient_month] == "unknown"
         params[:patient_month] = "July"
         params[:patient_day] = "1"
         estimate = true
      end
                                 
      if params[:patient_day] == "Unknown" or params[:patient_day] == "unknown"
         params[:patient_day] = "15" 
         estimate = true 
      end 

     if params[:patient_year] == "unknown" 
        # REFACTOR: This could be sped up considerably
        params[:patient_year] = (Encounter.find(:all, :conditions =>["patient_id = ?",session[:patient_id]], :order => "encounter_datetime Desc", :limit =>1).first.encounter_datetime + 3.months).year
        params[:patient_month] = (Encounter.find(:all, :conditions =>["patient_id = ?",session[:patient_id]], :order => "encounter_datetime Desc", :limit =>1).first.encounter_datetime + 3.months).month
        params[:patient_day] = (Encounter.find(:all, :conditions =>["patient_id = ?",session[:patient_id]], :order => "encounter_datetime Desc", :limit =>1).first.encounter_datetime + 3.months).day
      end
      
    end  
    return estimate
=end
  end

  # REFACTOR: We need to look more losely at the flash messages we are creating
  # REFACTOR: and the order of operations for creating related objects
  # REFACTOR: This is currently available as a GET not a POST (and is used as a GET)
  # This method is called from search_results.rhtml and is used to create a 
  # guardian for the current patient after looking them up first
  #
  # Session:
  # [<tt>:patient_id</tt>] The current patient id (to whom this guardian will be related)
  #
  # Valid Params:
  # [<tt>:name</tt>] The patient's first/given name
  # [<tt>:family_name</tt>] The patient's last/family name 
  # [<tt>:patient_gender</tt>] "Male" or "Female"
  def create_guardian
    @patient = Patient.new
    @patient.gender = params[:patient_gender]
    if @patient.save  
      @patientname = PatientName.new
      @patientname.given_name = params[:name]
      @patientname.family_name = params[:family_name]
      @patientname.patient_id = @patient.patient_id
      unless @patientname.save          
        flash[:error] = 'Could not save patientname'
        redirect_to :action => 'error'
      else
        flash[:notice] = 'Guardian was successfully created.'
				current_patient = Patient.find(session[:patient_id])
        RelationshipType.find(:all).each{|rel_type|
				  current_patient.remove_first_relationship(rel_type.name)
        }

        if session[:patient_program] == "HIV" and !params[:guardian_phone_number].blank?
          PatientIdentifier.create(@patient.id, params[:guardian_phone_number], "Home phone number")
        end
        redirect_to :action => 'set_guardian', :id => @patient.patient_id, 
          :relationship_type => params[:relationship_type],:redirect => params[:redirect]
      end
    end
  end
  
  def create
    estimate = set_date() # check for estimated birthdates and alter params if necessary
        
    if  params[:patient_year] == "Unknown"
      flash[:error] = 'You must estimate patient age before saving!!'
      redirect_to :action =>"new"
      return
    end
    #temporary hack to facillitate patient registration
#     patient_day = "15"  if params[:patient_day].nil? || params[:patient_day]==""
    # return render_text patient_day
   
    patient_birthdate = params[:patient_day].to_s + "-" + params[:patient_month].to_s + "-" + params[:patient_year].to_s 
  #put validation to check if patient has id then @patient should be initialised to this
  #
    if params[:patient_id].nil? or params[:patient_id].empty?
      if session[:patient_program] == "HIV"
        Location.set_current_location = Location.find_by_name(params[:location_name])
      end  
      begin
        @patient = Patient.new(params[:patient]) 
        @patient.save
        #render_text @patient.to_yaml and return
        @patientname = PatientName.new(params[:patient_name])
        @patientname.patient = @patient
        unless @patientname.save           
         flash[:error] = 'Could not save patientname'
         redirect_to :action => 'error'
        end
      rescue StandardError => message
        flash[:error] = message.to_s.humanize
        redirect_to request.referer and return
      end
    else
      @patient = Patient.find(params[:patient_id])
    end    
#    @patient.birthdate = Date.new(params[:patient_year].to_i, params[:patient_month].to_i, params[:patient_day].to_i)

		@patient.birthdate = patient_birthdate.to_date.to_s 
		@patient.birthdate_estimated = estimate  
  
    PatientAddress.create(@patient.id,params[:patientaddress])
    PatientIdentifier.create(@patient.id, params[:current_ta], "Traditional authority")
    PatientIdentifier.create(@patient.id, params[:other_name], "Other name")

    ask_extra_phone_numbers=GlobalProperty.find_by_property("ask_multiple_phone_numbers").property_value
    if ask_extra_phone_numbers=="true" 
      PatientIdentifier.create(@patient.id, params[:cell_phone], "Cell phone number")
      PatientIdentifier.create(@patient.id, params[:office_phone], "Office phone number")
    end

    PatientIdentifier.create(@patient.id, params[:home_phone], "Home phone number")
    PatientIdentifier.create(@patient.id, params[:occupation], "Occupation")
    PatientIdentifier.create(@patient.id, params[:p_address], "Physical address")

    if session[:existing_num].blank?
      patient_date_created = session[:encounter_datetime].to_date rescue Date.today
      print_new_ids = GlobalProperty.find_by_property("print_new_national_id").property_value rescue "false"
      if session[:patient_program].blank? and patient_date_created == Date.today and print_new_ids == "true"
        if params[:new_national_id].blank?
          @patient.set_new_national_id if session[:patient_program].blank? # setting new national i
        else
          PatientIdentifier.create!(:identifier => params[:new_national_id], 
            :identifier_type => PatientIdentifierType.find_by_name("New national id").id, :patient_id => @patient.id)
        end    
      end
      @patient.set_national_id # setting new national i
    else
      @patient.set_existing_national_id(session[:existing_num]) # setting existing national id
      session[:existing_num] = nil
    end  
     
    @patient_or_guardian = session[:patient_id].nil? ? "patient" : "guardian"
    if @patient_or_guardian !="guardian" and User.current_user.activities.include?("HIV Reception") and  GlobalProperty.find_by_property("use_filing_numbers").property_value == "true"
      @patient.set_filing_number
    end
                             
    if @patient.save
      if session[:patient_program].blank?
        user = User.current_user
        if user.has_role('Data Entry Clerk')
          image = user.user_properties.find_by_property('mastercard_image').property_value rescue nil
          arv_number = image.split('-').first.gsub(Location.current_arv_code,'').to_i rescue nil
          @patient.arv_number = arv_number.to_s if arv_number
          unless image.blank?
            unless image.match(@patient.image_arv_number) 
              user.assign_mastercard_image(image)
            end
          end
        end
      end

      flash[:info] = 'Patient was successfully created.'

      if session[:patient_program] == "TB"
        unless @patient.blank?
          redirect_to :action => "tb_card",:id => @patient.id and return
        else
          redirect_to :action => "add" and return
        end
      end
  
      #if the patient is being created from the mastercard
      if params[:create_from_mastercard] == "true"
        encounter_type = params[:art_visit][:encounter_type_id]
        if params[:create_first_visit] == "true"
          result = Encounter.create(@patient,params[:art_visit],session[:encounter_datetime],nil,encounter_type,nil)
        end
        params[:form_id] = params[:hiv_staging][:encounter_type_id]
        encounter_type = params[:hiv_staging][:hiv_encounter_type_id]
        if params[:create_staging] == "true"
          result = Encounter.create(@patient,params[:hiv_staging],session[:encounter_datetime],nil,encounter_type,nil)
        end
        if params[:create_guardian] == "true"
          session[:patient_id] = @patient.id
          redirect_to :action => "create_guardian",:patient_gender => params[:guardian_gender],
          :family_name => params[:guardian_family_name],:name =>params[:guardian_name],
          :relationship_type => params[:relationship_type],
          :redirect => "mastercard",:guardian_phone_number => params[:guardian_phone_number].to_s ; return
        end

        if session[:patient_program] == "HIV"
          if @patient.arv_number.blank?
            session[:patient_id] = nil
            redirect_to :action => 'mastercard_modify', :id => @patient.patient_id, 
              :show_previous_visits =>"true",:field => "arv_number" and return
          else  
            session[:patient_id] = nil
            redirect_to :action => 'retrospective_data_entry', :id => @patient.patient_id, 
              :show_previous_visits =>true and return
          end
        end  
        redirect_to :action => "mastercard" ; return
      end

      if GlobalProperty.find_by_property("use_filing_numbers").property_value == "true" and User.current_user.activities.include?("HIV Reception")
        archived_patient = @patient.patient_to_be_archived
        message = printing_message(@patient,archived_patient,creating_new_patient=true) unless archived_patient.blank?
        print_and_redirect("/label/filing_number_and_national_id/#{@patient.id}", "/patient/set_patient/#{@patient.id}",message,true,@patient.id) unless message.blank?
        print_and_redirect("/label/filing_number_and_national_id/#{@patient.id}", "/patient/set_patient/#{@patient.id}") if message.blank?
      else
        print_and_redirect("/label/national_id/#{@patient.id}", "/patient/set_patient/#{@patient.id}")
      end
    else
      redirect_to :action => 'new'
    end
  end
  
  def printing_message(new_patient,archived_patient,creating_new_filing_number_for_patient=false)
   arv_code = Location.current_arv_code
   new_patient_name = new_patient.name
   new_filing_number = Patient.printing_filing_number_label(new_patient.filing_number)
   old_active_filing_number = Patient.printing_filing_number_label(archived_patient.archived_patient_old_active_filing_number)
   dormant_filing_number = Patient.printing_filing_number_label(archived_patient.filing_number)
   active_patient_old_dormant_filing_number = dormant_filing_number unless creating_new_filing_number_for_patient

      return "<div id='patients_info_div'>
     <table>
       <tr><td class='filing_instraction'>Filing actions required</td><td class='filing_instraction'>Name</td><td>Old Label</td><td>New label</td></tr>
       <tr><td>Move Active → Dormant</td><td class='filing_instraction'>#{archived_patient.name}</td><td  class=\'old_label\'><p class=active_heading>#{arv_code} Active</p><b>#{old_active_filing_number}</b></td><td  class=\'new_label\'><p class=dormant_heading>#{arv_code} Dormant</p><b>#{dormant_filing_number}</b></td></tr>  
      #{if !creating_new_filing_number_for_patient
        '<tr><td>Move Dormant → Active</td><td class=\'filing_instraction\'>'+ new_patient_name +'</td><td  class=\'old_label\'><p class=dormant_heading>'+ arv_code +' Dormant</p><b>'+ active_patient_old_dormant_filing_number +'</b></td><td  class=\'new_label\'><p class=active_heading>'+ arv_code +' Active</p><b>'+ new_filing_number +'</b></td></tr>'  
      else
       '<tr><td>Add to Active</td><td class=\'filing_instraction\'>'+ new_patient_name  +'</td><td  class=\'old_label\'><p class=dormant_heading>'+ arv_code +' Dormant</p>&nbsp;&nbsp;</td><td  class=\'new_label\'><p class=active_heading>'+ arv_code +' Active</p><b>'+ new_filing_number +'</b></td></tr>'
      end}
       <tr><td></td><td></td><td><button class='page_button' onmousedown='print_filing_numbers();'>Print</button></td><td><button  class='page_button' onmousedown='next_page();'>Done</button></td></tr>
     </table>"
   
  end

  def edit
    @patient = Patient.find(params[:id])
    @patient_name = @patient.patient_names[0]
    @patient_sex=@patient.gender
    #birth_type =  PatientIdentifierType.find_by_name("Birth traditional authority").patient_identifier_type_id
    name_type =  PatientIdentifierType.find_by_name("Other name").patient_identifier_type_id
    ta_type =  PatientIdentifierType.find_by_name("Traditional authority").patient_identifier_type_id
    cell_phone_number =  PatientIdentifierType.find_by_name("Cell phone number").patient_identifier_type_id
    home_phone_number =  PatientIdentifierType.find_by_name("Home phone number").patient_identifier_type_id
    office_phone_number =  PatientIdentifierType.find_by_name("Office phone number").patient_identifier_type_id
    occupation =  PatientIdentifierType.find_by_name("Occupation").patient_identifier_type_id
    physical_address =  PatientIdentifierType.find_by_name("Physical address").patient_identifier_type_id
    patient_date = @patient.birthdate unless @patient.birthdate.blank?
    @patient_birthyear=patient_date.year.to_s  unless patient_date.nil? 
    @patient_birthmonth=patient_date.month.to_s unless patient_date.nil?
    @patient_birthdate=patient_date.day.to_s  unless patient_date.nil?

    @occupation = PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,occupation).identifier rescue ""
    @p_address = PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,physical_address).identifier rescue ""
    #@patient_birth_traditional_authority = PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,birth_type).identifier
    @patient_other_name = PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,name_type).identifier rescue ""
    @current_ta = PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,ta_type).identifier rescue ""
    @residence = PatientAddress.find_by_patient_id(@patient.id).city_village rescue ""
    @cell_phone_number = PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,cell_phone_number).identifier rescue ""
    @home_phone_number = PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,home_phone_number).identifier rescue ""
    @office_phone_number = PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,office_phone_number).identifier rescue ""
  end

  def update
    @patient = Patient.find(params[:id])

    estimate = set_date()
    
    if  params[:patient_year]== "Unknown" and patient_estimated_birthyear ==""
      flash[:error] = 'Estimate patient age before saving!!'
      redirect_to :action =>"edit"
      return
    end
    
    patient_birthdate=params[:patient_day] + "-" + params[:patient_month] + "-" + params[:patient_year]
    patient_birthdate =  patient_birthdate.to_date.to_s
    @patient.birthdate = patient_birthdate
    @patient_name = @patient.patient_names[0]
    if estimate== true
      @patient.birthdate_estimated = estimate
    end
    @patient.gender= params[:patient][:gender]
    
    @patientaddress = PatientAddress.find_by_patient_id(@patient.id)
    name_type =  PatientIdentifierType.find_by_name("Other name").patient_identifier_type_id
    ta_type =  PatientIdentifierType.find_by_name("Traditional authority").patient_identifier_type_id
    cell_phone_number =  PatientIdentifierType.find_by_name("Cell phone number").patient_identifier_type_id
    home_phone_number =  PatientIdentifierType.find_by_name("Home phone number").patient_identifier_type_id
    office_phone_number =  PatientIdentifierType.find_by_name("Office phone number").patient_identifier_type_id
    occupation =  PatientIdentifierType.find_by_name("Occupation").patient_identifier_type_id
    physical_address =  PatientIdentifierType.find_by_name("Physical address").patient_identifier_type_id
       
    @occupation =PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,occupation)
    @p_address =PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,physical_address)
    @other_name =PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,name_type) 
    @current_ta =PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,ta_type)
    @cell_phone = PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,cell_phone_number)
    @home_phone = PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,home_phone_number)
    @office_phone = PatientIdentifier.find_by_patient_id_and_identifier_type(@patient.id,office_phone_number)
    @birth_place= PatientAddress.find_by_patient_id(@patient.id)
    @patient_name.update_attributes(params[:patient_name])  
      
    if @current_ta.nil?
      @current_ta = PatientIdentifier.new
      @current_ta.patient = @patient
      @current_ta.identifier_type = PatientIdentifierType.find_by_name("Traditional authority").patient_identifier_type_id
      @current_ta.location_id = Location.current_location.id
    end
    @current_ta.identifier = params[:current_ta][:identifier]
    @current_ta.save
    
   
    if  @p_address.nil?
      @p_address = PatientIdentifier.new
      @p_address.patient = @patient
      @p_address.identifier_type = PatientIdentifierType.find_by_name("Physical address").patient_identifier_type_id
      @p_address.location_id = Location.current_location.id
    end
    @p_address.identifier = params[:p_address][:identifier]
    @p_address.save
  
   if @cell_phone.nil?
      @cell_phone = PatientIdentifier.new
      @cell_phone.patient = @patient
      @cell_phone.identifier_type = PatientIdentifierType.find_by_name("Cell phone number").patient_identifier_type_id
      @cell_phone.location_id = Location.current_location.id
   end
   @cell_phone.identifier = params[:cell_phone][:identifier]
   @cell_phone.save
   
   
   if @home_phone.nil?
      @home_phone = PatientIdentifier.new
      @home_phone.patient = @patient
      @home_phone.identifier_type = PatientIdentifierType.find_by_name("Home phone number").patient_identifier_type_id
      @home_phone.location_id = Location.current_location.id
   end
   @home_phone.identifier = params[:home_phone][:identifier]
   @home_phone.save
                            
   if @office_phone.nil?
     @office_phone = PatientIdentifier.new
     @office_phone.patient = @patient
     @office_phone.identifier_type = PatientIdentifierType.find_by_name("Office phone number").patient_identifier_type_id
     @office_phone.location_id = Location.current_location.id
   end
   @office_phone.identifier = params[:office_phone][:identifier]
   @office_phone.save
                          
                                                                                                                             
   if @occupation.nil?
     @occupation = PatientIdentifier.new
     @occupation.patient = @patient
     @occupation.identifier_type = PatientIdentifierType.find_by_name("Occupation").patient_identifier_type_id
     @occupation.location_id = Location.current_location.id
   end
   @occupation.identifier = params[:occupation][:identifier]
   @occupation.save
   
  if @birth_place.nil?
     @birth_place = PatientAddress.new
     @birth_place.patient = @patient
     @birth_place.city_village =  params[:patient][:birthplace] 
  end
  @birth_place.city_village = params[:patient][:birthplace]
  @birth_place.save 
  
  
  
  
  if @other_name.nil?
     @other_name = PatientIdentifier.new
     @other_name.patient = @patient
     @other_name.identifier_type = PatientIdentifierType.find_by_name("Other name").patient_identifier_type_id
     @other_name.location_id = Location.current_location.id
  end
  @other_name.identifier = params[:other_name][:identifier]
  @other_name.save
                   
    
  if @patient.update_attributes(params[:patient])
     flash[:error] = 'Patient was successfully updated.'
     redirect_to :action => 'list'
  else
    render :action => 'edit'
  end
end

  def change
    # we used to do this with reset_session but it did strange things

# use following command to find all uses of the session object
# grep -rni session app/controllers/ | grep -v svn |  perl -p -e 'm/(session.*?])/; $_ = $1 ."\n"' | sort | uniq

    # don't delete user, location or ip_address
    session[:action_id] = nil
    session[:concept_container] = nil
    session[:current_action] = nil
    session[:current_controller] = nil
    unless session[:reset_encounter_time]
      session[:encounter_datetime] = nil
    end
    session[:encounter_location] = nil
    session[:is_retrospective] = nil
    session[:patient_id] = nil
    session[:transfer_in] = nil

    unless session[:data_tools].blank? 
      data_tools  =  session[:data_tools]
      session[:data_tools] = nil
      next_form  =  data_tools.split("|")
      controller_name = next_form[0]
      action_name = next_form[1]
      report_type = next_form[2]
      parameters = next_form[3] rescue ""
    
      if report_type == "dispensations_without_prescriptions"                 
        redirect_to :controller => controller_name,:action => action_name,:report_type => report_type,
                      :report => parameters
        return
      elsif report_type =="prescriptions_without_dispensations"    
        redirect_to :controller => controller_name,:action => action_name,:report_type => report_type,
                    :report => parameters
        return
      elsif report_type =="patients_with_multiple_start_reasons"    
        redirect_to :controller => controller_name,:action => action_name,
                    :quater => parameters,:report_type => report_type
        return
      elsif report_type == "in_arv_number_range"    
        min = parameters.split(",")[0]
        max = parameters.split(",")[1]
        quater = parameters.split(",")[2]
        redirect_to :controller => controller_name,:action => action_name,
                    :arv_number_end => max ,:arv_number_start =>min, :quater => quater
        return
      elsif report_type =="non-eligible_patients_in_cohort"   
        id = "start_reason_other"
        report_type = "Non-eligible patients in: #{parameters}"
        start_date, end_date = Report.cohort_date_range(parameters)
        start_date = start_date.to_s
        end_date = end_date.to_s
        redirect_to :controller => "reports",:action => "cohort_debugger",
                    :id => id,:report_type => report_type,
                    :start_date => start_date,:end_date => end_date
        return
      end
    end

    redirect_to :action => 'menu'
  end
  
  def not_retrospective_data_entry
    session[:is_retrospective]  = false
    session[:encounter_datetime]  = Time.now
    redirect_to :action => "menu"
  end

  def reset_datetime
    session[:encounter_datetime] = nil
    session[:reset_encounter_time] = nil
    redirect_to :action => "menu" and return
  end
  
  def set_datetime_for_retrospective_data_entry

    @needs_date_picker = true
    if request.post? 
			unless params["retrospective_patient_day"]== "" or params["retrospective_patient_month"]== "" or params["retrospective_patient_year"]== ""
				date_of_encounter = Time.mktime(params["retrospective_patient_year"].to_i,params["retrospective_patient_month"].to_i,params["retrospective_patient_day"].to_i,0,0,1) # set for 1 second after midnight to designate it as a retrospective date
        if date_of_encounter.to_date < Date.today
          session[:encounter_datetime] = date_of_encounter
          session[:is_retrospective]  = true
          if User.current_user.activities.include?("General Reception")
            session[:reset_encounter_time] = true
          end  
        else
          redirect_to :action => "menu", :id => nil ; return
        end
			end 
      redirect_to :action => "menu", :id => nil,:set_encounter_datetime => date_of_encounter
    end

  end

  def set_patient
	  arv_header = Location.current_arv_code
   # render:text => params[:id].to_yaml and return
    if params[:id] =~ /P.*/ #if national id
      person = Patient.find_by_national_id(params[:id]).first
    elsif params[:id] =~ /#{arv_header}.*/
      person = Patient.find_by_arv_number(params[:id])
    else
      person = Patient.find(params[:id])  
    end

    unless session[:merging_patients].blank?
      div_to_update = session[:merging_patients].split(';').first rescue nil
      if div_to_update == 'left_div'
        @second_patient =  session[:merging_patients].split(';')[2] rescue nil
        @first_patient = person.id
      elsif div_to_update == 'right_div'
        @first_patient =  session[:merging_patients].split(';')[1] rescue nil
        @second_patient = person
      end
      redirect_to :action => "merge_show",:sec_pat =>@second_patient,:first_pat =>@first_patient ; return
    end

    if person.blank?
      flash[:error] = "Sorry,Patient with id #{params[:id]} not found"
      redirect_to(:controller => "patient", :action => "menu") and return
    end

    session[:patient_id] = person.id
    patient = person
    
    # Check intersection of user's and patient's programs
    if (User.current_user.current_programs & patient.programs).length == 0
      redirect_to :action => "add_program" and return
    end

    if User.current_user.activities.include?("Enter past visit")
      redirect_to :action => "set_datetime_for_retrospective_data_entry"
    else
      session[:encounter_datetime] = Time.now
      redirect_to :action =>"summary"
    end
  end

  def set_guardian
    # make sure we have a patient in the session
    return if session[:patient_id].nil?

    if params[:id] =~ /P.*/ #if national id
      person = Patient.find_by_national_id(params[:id]).first
    else
      person = Patient.find(params[:id])
    end

    patient = Patient.find(session[:patient_id])
    patient.reload  # not sure why we need to do this - workaround for now
    # if there is no guardian set, and a patient is selected, set the guardian to the patient with the id param
    begin
      patient.set_art_guardian_relationship(person,params[:relationship_type])
    rescue
      nil
    end
   
    if params[:redirect] == "mastercard"
      session[:patient_id] = nil
      if session[:patient_program] == "HIV" and patient.arv_number.blank?
        redirect_to :action => 'mastercard_modify', :id => patient.patient_id, 
          :show_previous_visits =>"true",:field => "arv_number" and return
      end  
      redirect_to :action => "retrospective_data_entry" ,
        :id => patient.id,:show_previous_visits => "true"; return
    end

    redirect_to :action => "menu" 
  end

  def add_program
    patient = Patient.find(session[:patient_id])
    if params[:patient]
      patient.add_programs(Program.find(params[:patient][:program_id]))
      redirect_to(:controller => 'patient', :action => "menu")
    else
      # Only show programs patient isn't already in
      @available_programs = User.current_user.current_programs - patient.programs
      if @available_programs.length == 1
        auto_add_program = GlobalProperty.find_by_property("auto_add_program_during_registration").property rescue "true"
        if auto_add_program == "true"
          patient.add_programs(@available_programs)
          redirect_to(:controller => 'patient', :action => "menu")
        end
      elsif @available_programs.length == 0
        #flash[:error] = "No available programs for this patient"
        redirect_to(:controller => 'patient', :action => "menu")
      end
    end
  end


  # Return a menu for patient actions. Several actions are redirected here, 
  # including:
  #
  #  :index
  #  :change
  #  :not_retrospective_data_entry
  #  :set_datetime_for_retrospective_entry
  #  :set_patient
  #  :set_guardian
  #  :add_program
  #  :archive_patients
  #  :patient_search_results
  #  :update_outcome
  #  :create_arv_number
  #  :summary
  #  :create_filing_number
  #
  # User roles and privileges are checked to determine whats available on the
  # menu. Additionally the global properties use_filing_numbers and
  # use_find_by_arv_number
  #
  # Session params:
  # [<tt>:action_id</tt>] This param is reset
  # [<tt>:patient_id</tt>] Id used to lookup the patient for the specific menu
  # [<tt>:encounter_datetime</tt>] Date of the retrospective entry, or now
  # [<tt>:is_retrospective</tt>] Used to determine options for retrospective entry
  #
  # Valid params:
  # [<tt>"no_auto_load_forms"</tt>] Checks if the auto load forms should be off. Note, this param is not a symbol but a quoted string, and it only checks that the value does not equal +"true"+

  def switch_location
    session[:location] = params[:location_to_be_set]
    if session[:location] == "genrecpt"
      session[:switched_locations] = User.current_user.activities
      User.current_user.activities = ["General Reception"]
    else
      unless session[:switched_locations].blank? 
        User.current_user.activities = session[:switched_locations] 
      end rescue nil
      session[:switched_locations] = nil
      if User.current_user.activities.blank?
        redirect_to :controller => "user" ,:action =>"activities" and return
      elsif User.current_user.activities.include?("General Reception")  
        User.current_user.activities = []
        redirect_to :controller => "user" ,:action =>"activities" and return
      end  
    end    
    redirect_to :action => "menu" and return
  end

  def find_by_identifier
    if request.method == :post
      identifier = params[:identifier].upcase
      redirect_to :controller => "encounter",:action => "scan",:barcode => identifier
      return
    end
  end

  def menu
    unless session[:patient_program].blank?
      redirect_to :action => "retrospective_data_entry_menu" ; return
    end

# TODO Do we need to speak with MoH about getting these in the spec
#    @last_art_visit = none, different clinic, this clinic
#    @arv_history = never, previously yet but not currently, currently yes
    session[:action_id]=""
    @user = User.current_user
    current_location_name = Location.current_location.name
    @user_is_superuser = false
    @user_is_superuser = true if @user.has_role('superuser')

#    session[:registration_type]=params[:id] unless params[:id].nil? #TODO now
  
    @show_general_reception_stats = false  
    @show_lab_trail = false
    @show_set_filing_number = false
    @show_find_by_arv_number = false
    @show_archive_patient = false
    @show_assign_new_filing_number = false
    @show_change_date = false
    @show_filing_number = false
    @show_create_filing_label = false
    @show_find_patient = false
    @show_find_or_register_patient = false
    @show_find_or_register_guardian = false
    @show_select_patient = false
    
    @show_dispensation = false
    @show_print_visit_summary = false
    @show_print_national_id_label = false
    @show_print_filing_label = false
    @show_create_user = false
    @show_bmi = false
    @show_who_stage = false
    @show_user_management = false
    @show_update_outcome = false
    @show_next_appointment_date = false
    @show_out_patient_diagnosis = false
    @show_set_datetime = false
    @show_reset_date = false
    @show_view_reports = false
    @show_standard_visit_encounter = false
    @show_patient_dash_board = false
    @show_decentralize = false
    @show_switch_location = false
    @show_find_by_identifier = false

     
    @show_mastercard =false 
    @show_outcome=false
    @show_print_demographics = false
    session[:show_patients_mastercards] = false
    @show_change_task = true
    session[:current_mastercard_ids] = nil
    session[:current_mastercard_id] = nil
    session[:existing_num] = nil
    session[:merging_patients] = nil

    @user_activities = @user.activities
    #if calling action is data cleaning 

    
    unless params[:path].blank?
      session[:data_tools] = params[:path] 
    end

    if params['data_cleaning']
				session[:encounter_datetime] = Time.mktime(params["retrospective_patient_year"].to_i,params["retrospective_patient_month"].to_i,params["retrospective_patient_day"].to_i,0,0,1) # set for 1 second after midnight to designate it as a retrospective date
				session[:is_retrospective]  = true
        session[:patient_id] = params['id']
    end
    # If we don't have a patient then show button to find one
    if session[:patient_id].blank?
      if @user_activities.to_s.include?("Reception")
        @show_find_or_register_patient = true
        @show_set_filing_number = true if GlobalProperty.find_by_property("show_set_filing_number").property_value == "true" rescue false
        @show_general_reception_stats = true if @user_activities.include?("General Reception")
      else
        @show_find_patient = true
      end

      @show_standard_visit_encounter = true if @user_is_superuser


      #TODO
      show_switch_location = GlobalProperty.find_by_property("show_switch_location").property_value rescue "false"
      if @user.roles.map{|r|r.role}.join(",").match(/Clinician|Nurse/) and show_switch_location == "true"
        @show_switch_location = true
        if session[:location] == "artclinic"
          @switched_location = "Switch to OPD"
          @location_to_be_set = "genrecpt"
        else
          @switched_location = "Switch to ART"
          @location_to_be_set = "artclinic"
        end   
      end


#TODO
      show_find_by_identifier = GlobalProperty.find_by_property("show_find_by_identifier").property_value rescue "false"
      @show_find_by_identifier = true if show_find_by_identifier == "true"

      
#TODO should this be here?
      session[:is_retrospective] = nil
      session[:encounter_datetime] = nil if session[:reset_encounter_time].blank?
      
      @show_encounter_summary = true if @user_activities.include?("HIV Reception") || @user_activities.include?("HIV Staging") || @user_activities.include?("ART Visit")
      show_find_by_arv_number = GlobalProperty.find_by_property("use_find_by_arv_number")
      @show_find_by_arv_number = true if show_find_by_arv_number.property_value == "true" unless show_find_by_arv_number.blank? 
      @show_user_management = true if @user_is_superuser #.user_roles.collect{|r|r.role.role}.include?("superuser")
      
      if @user_activities.include?("General Reception") 
        if !params[:set_encounter_datetime].blank? 
          if params[:set_encounter_datetime].to_date < Date.today  
            @show_reset_date = true
            session[:encounter_datetime] = params[:set_encounter_datetime].to_time
          end
        elsif session[:reset_encounter_time]  
          @show_reset_date = true
        else
          @show_set_datetime = true
        end
        unless current_location_name == "Lighthouse"  
          @show_view_reports = true unless current_location_name == "Martin Preuss Centre"
        end  
        @show_change_task = false 
      end
   
    else
      @patient = Patient.find(session[:patient_id])

      @show_standard_visit_encounter = true if @user.has_role('Data Entry Clerk')

      if @patient.available_programs.nil? and @user.current_programs.length > 0
        redirect_to :controller => "form", :action => "add_programs" and return
      end

      if @user_activities.include?("Enter past visit") and ! session[:is_retrospective]
       redirect_to :action => "set_datetime_for_retrospective_data_entry" and return
      end

      session[:encounter_datetime]=Time.now if session[:encounter_datetime].nil?
			session_date = session[:encounter_datetime].to_date

      @outcome = @patient.outcome
      @next_forms = nil
      @show_outcome = true if @outcome and @outcome.name != 'On ART'
      @next_forms = @patient.next_forms(session_date, @outcome)
      @next_activities = @next_forms.collect{|f|f.type_of_encounter.name}.uniq rescue []
      unless @next_forms.blank?
        # remove any forms that the current users activities don't allow
        @next_forms.reject!{|frm| !@user_activities.include?(frm.type_of_encounter.name)}
       	if @next_forms.length == 1 and params["no_auto_load_forms"] != "true"
          disable_update_guardian =  GlobalProperty.find_by_property("disable_update_guardian").property_value rescue "false"
          if disable_update_guardian == "false"
            if @next_forms.first.name =~ /[HIV|TB] Reception/i and @patient.art_guardian.blank?
              redirect_to :action => "search", :mode => "guardian" ; return
            end
          end  
          redirect_to :controller => "form", :action => "show", :id => @next_forms.first.id and return
        end
      end
      #Redirect to Give drugs if the conditions apply
      if @next_forms and @next_forms.length == 0 and  @patient.encounters.find_by_type_name_and_date("Give drugs", session[:encounter_datetime]).empty? and @patient.prescriptions(session[:encounter_datetime]).length > 0
        @next_activities << "Give drugs"
        if params["no_auto_load_forms"] != "true" and  @user_activities.include?("Give drugs")
          redirect_to :controller => "drug_order", :action => "dispense" and return
        end
      end

      @show_dispensation = true if @user_activities.include?("Give drugs") and not @patient.outcome_status(session[:encounter_datetime].to_date - 1) =~ /Died|Transfer/

      @show_mastercard = true if @patient.art_patient? or @user_activities.include?("General Reception")
      @show_update_outcome = true if @user_activities.include?("Update outcome")
      if Location.current_location.name == "Zomba Central Hospital"
        @show_decentralize = true if @user_activities.include?("Update outcome")
      end
      if @user_activities.to_s.include?("Reception")
        arv_national_id=@patient.ARV_national_id
        @show_print_national_id_label = true
      end
      if @user_activities.include?("HIV Reception") and GlobalProperty.find_by_property("use_filing_numbers").property_value == "true"
        @show_filing_number = true
        @show_print_filing_label = true unless @patient.filing_number.blank?
        @show_create_filing_label = true if @user_activities.include?("HIV Reception") and @patient.filing_number.blank?
      end 
      
      @show_select_patient = true

      # Only show bmi if the weight was taken today
      current_weight = @patient.observations.find_last_by_concept_name("Weight")
      if current_weight.obs_datetime == Date.parse(session[:encounter_datetime].to_s)
        bmi = @patient.current_bmi
        @bmi = sprintf("%.1f", bmi) unless bmi.nil?
      end unless current_weight.nil?

      # TODO this code needs testing!
      # if today's weight observation happened 3 months or more since starting art
      #
      if (session[:encounter_datetime] - @patient.date_started_art) > 3.months
        @percent_weight_changed_over_past_three_months = @patient.percent_weight_changed(3.months.ago(session[:encounter_datetime].to_time),session[:encounter_datetime])
        @has_lost_5_percent_of_weight_over_three_months_while_on_ART = true if @percent_weight_changed_over_past_three_months <= -0.05 rescue nil
        @percent_weight_changed_over_past_three_months = sprintf("%.0f", @percent_weight_changed_over_past_three_months*100) rescue nil#format for printing
        if (session[:encounter_datetime] - @patient.date_started_art) > 6.months and not @percent_weight_changed_since_starting_art.blank?
          @percent_weight_changed_since_starting_art = @patient.percent_weight_changed(@patient.date_started_art, session[:encounter_datetime])
        end
      end unless @patient.date_started_art.nil?

      @show_who_stage = true unless @patient.encounters.find_by_type_name("HIV Staging").empty?
     
      @show_find_or_register_guardian = true if @user_activities.include?("HIV Reception") and @patient.art_guardian.nil?

      @show_next_appointment_date = true
      @next_appointment_date = @patient.next_appointment_date(session[:encounter_datetime]) rescue nil

      if not @patient.drug_orders_for_date(session[:encounter_datetime]).empty?
        @show_print_visit_summary = true if not @user_activities.include?("General Reception")
      end
      lab_trail = GlobalProperty.find_by_property("show_lab_trail").property_value rescue "false"
      lab_trail = lab_trail=="false" ? false : true
      @show_lab_trail = true if (@user_activities.include?("HIV Staging") ||  @user_activities.include?("ART Visit")) and lab_trail
      @show_print_demographics = true if @patient.reason_for_art_eligibility || @patient.who_stage
      
      current_encounters = @patient.current_encounters(session[:encounter_datetime])

      if @user_activities.include?("General Reception")
        @show_change_task = false 
        gen_encounter_ids = EncounterType.find(:all,:conditions =>["name IN ('Outpatient diagnosis','Referred')"]).collect{|type|type.id} 
        gen_reception_id = EncounterType.find(:first,:conditions =>["name = ?",'General Reception']).id

        gen_reception = Encounter.find(:all,
                                   :joins => "INNER JOIN obs ON encounter.patient_id = obs.patient_id",
                                   :conditions =>["encounter_type = #{gen_reception_id} AND 
                                   obs.patient_id = ? AND DATE(encounter_datetime)=? AND obs.voided = 0",
                                   @patient.id,session[:encounter_datetime].to_date])  

        gen_reception_encounters = Encounter.find(:all,
                                   :joins => "INNER JOIN obs ON encounter.patient_id = obs.patient_id",
                                   :conditions =>["encounter_type IN (?) AND obs.patient_id = ? AND 
                                   DATE(encounter_datetime)=? AND obs.voided = 0",
                                   gen_encounter_ids,@patient.id,session[:encounter_datetime].to_date])  

        @show_out_patient_diagnosis = true if !gen_reception.blank? and gen_reception_encounters.blank?
        @outpatient_session = true
        @show_patient_dash_board = true
        current_encounters.delete_if{|enc|
          !enc.name.include?("Outpatient diagnosis") and !enc.name.include?("Referred") and !enc.name.include?("General Reception")
        }
        @bmi = nil
        @show_who_stage = false
        @show_filing_number = false
        @next_activities = nil
        @show_outcome = nil
        @show_encounter_summary = false
        @show_next_appointment_date =false
        @show_general_reception_stats = false
        @show_mastercard =false
        @show_encounter_summary =false
        @show_outcome=false
        @show_print_demographics = false
      else
        current_encounters.delete_if{|enc|
          next if enc.name.blank?
          enc.name.include?("Outpatient diagnosis") || enc.name.include?("Referred") || enc.name.include?("General Reception")
        }
      end  

      @current_encounter_names = current_encounters.collect{|enc|enc.name}.uniq.reverse if @user_is_superuser
      @current_encounter_names = current_encounters.collect{|enc|enc.name if enc.creator == @user.id}.compact.uniq.reverse unless @user_is_superuser
      @current_encounter_names.delete("Barcode scan")

    end
   
    unless @user_activities.include?("General Reception") 
      @show_change_date = true if session[:encounter_datetime].to_date < Date.today rescue false
    end

    if @show_out_patient_diagnosis and params[:no_auto_load_forms].blank?
      #redirect_to :controller => "diagnosis",:action => "new" ; return
    end
      
    render(:layout => "layouts/menu")
  end

  def archive_patients
   Patient.archive_patient(params[:id])
   flash[:info] = 'Patient was successfully archived.'
   redirect_to :action =>"menu"
  end
  
  def reassign_patient_filing_number
   current_patient = Patient.find(params[:id])
   current_patient.set_filing_number
   archived_patient = current_patient.patient_to_be_archived
   message = printing_message(current_patient,archived_patient) unless archived_patient.blank?
   print_and_redirect("/label/filing_number/#{current_patient.id}", "/patient/summary",message,next_button=true) unless message.blank?
   print_and_redirect("/label/filing_number/#{current_patient.id}", "/patient/summary") if message.blank?
   
   flash[:info] = 'Patient was successfully given a new filing number.'
  end

  def patient_search_results
    # first thing to do is determine if the id is valid
    id_validation = params[:id].match("P") 
    diff_format= params[:id].strip[1..1].to_i      
    if id_validation.nil? 
      flash[:error] = "Can not find patient, ID is of wrong format"
      if  session[:action_id]== "search_by_national_id"
        redirect_to :action =>"search_by_national_id"
      else
        redirect_to :action =>"menu"
      end
      return
    else
      chk_digit= params[:id].slice(12..12)
      if diff_format != 0
        number_tobe_chk= params[:id].slice(1..11)
      else
        number_tobe_chk= params[:id].slice(2..11)  
      end
      check_number= PatientIdentifier.calculate_checkdigit(number_tobe_chk)
         
      if check_number != chk_digit.to_i

        flash[:error] = "Patient with id #{params[:id]} not found, check digit does not match with ID"
        if   session[:action_id]== "search_by_national_id"
          redirect_to :action =>"search_by_national_id"
        else
          redirect_to :action =>"menu"
        end
        return
      end 
    end
   
    # id is valid so lets look for a match 
    patient_identifier_type_id=PatientIdentifierType.find_by_name("National id").patient_identifier_type_id
    patient = PatientIdentifier.find_by_identifier_and_identifier_type(params[:id],patient_identifier_type_id)
    patient_id = patient.patient_id if patient
    if patient_id.nil?
      #TEMPID
      flash[:error] = "Patient not found"
      redirect_to :action => "search_by_national_id"
    else
      redirect_to :action =>"menu"
    end

#       render_text @patient.patient_id
  end

  def search
    image_dir = GlobalProperty.find_by_property('mastercard_image_path').property_value rescue nil
    user = User.current_user
    arv_code = Location.current_arv_code
    if user.has_role('Data Entry Clerk') and image_dir
      patient_id = session[:patient_id] rescue nil

      patient = Patient.find(patient_id) rescue nil
      if patient.nil? and user.user_mastercards.length > 0
        arv_number = user.user_mastercards.last.arv_number.gsub(arv_code,'').to_i rescue nil
        patient = Patient.find_by_arvnumber(arv_code + arv_number.to_s) rescue nil
      end
      # if first time entry or finished data entry
      if (patient.nil? && user.user_mastercards.length < 1) ||
         (patient && patient.drug_orders.length > 1)
         
        # move file
        arv_number = user.user_mastercards.find(:last).arv_number rescue nil
        Dir["#{image_dir}/#{arv_number}*"].each do |filename|
          dest_dir = "#{image_dir}/../mc2"
          Dir.mkdir(dest_dir) unless File.exist?(dest_dir)
          File.rename(filename, "#{image_dir}/../mc2/#{File.split(filename).last}")
        end if arv_number
        user.assign_available_mastercard
      end
      
    end

    session[:existing_num] = params[:existing_num] unless params[:existing_num].blank?
    session[:merging_patients] = "#{params[:div]};#{params[:left_pat]};#{params[:right_pat]}" unless params[:div].blank?
  end
  
  def search_results
    # given first name, last name, sex, birthdate, current place of residence
    @patients = Patient.find_by_first_last_sex(params["first"],params["last"],params["sex"])
    @first_name = params["first"]
    @last_name = params["last"]
    @sex = params["sex"]
    @relationship_type = params["relationship_type"]
    @patient_or_guardian = session[:patient_id].nil? ? "Patient" : "Guardian"
    render:layout => true
# TODO handle nil
  end 

  def patient_search_names
    @patient_or_guardian = params[:mode]
    #  render(:layout => "layouts/search")
  end

  def search_by_name 
    patient_hash = Hash.new
    @search_result_by_other_details =Array.new
    @patients_by_name = Array.new
    @search_result_by_other_detail=Array.new
    @search_result_by_other_details_national_id=Array.new
    @patients_by_birthday=Array.new
    @patients_by_birthmonth= Array.new
    @patients_by_birthyear=Array.new
    name1 = params[:name]
    name2 = params[:other_name]
    name3 = params[:family_name]
    national_id=params[:national_id]
    national_id=national_id.split("-") if national_id !=""
    national_id=national_id.to_s if national_id !=""
    estimate= params[:patient_estimate]

    patientyear=params[:patient_birth_year]
    patientmonth=params[:patient_birth_month]
    patientdate=params[:patient_birth_date]
    patientdate= patientdate['birthday(3i)'].to_i
    patientmonth = patientmonth['birthmonth(2i)'].to_i
    patientyear =  patientyear['birthyear(1i)'].to_i

    @search_result_by_other_details_national_id = Patient.find_by_national_id(national_id) unless national_id == ""

#......................................................................
  #  @patients_by_name = Patient.find_by_name(name1) unless name1 == ""  
   # empty_array=@patients_by_name.empty?
   # if empty_array==true
   #   @patients_by_name = Patient.find_by_name(name2) unless name2 == ""
   # else
    #  @patients_by_name = @patients_by_name & Patient.find_by_name(name2) unless name2 == ""
   # end
#.....................................................................................

    if name3 !="" and  name1=="" and  name2==""
       @patients_by_name = Patient.find_by_patient_surname(name3)
    end
                  
    if name1 !="" and  name3 !=""  and  name2 ==""
        @patients_by_name = Patient.find_by_patient_name(name1,name3)
    end  
   
    if name1 !="" and  name2 !="" and name3 !=""
       @patients_by_name =@patients_by_name & Patient.find_by_patient_names(name1,name2,name3)
    end
                   
    @empty_patients_by_name = @patients_by_name.empty?
        
    @patients_by_birthday=Patient.find_by_birthday(patientdate) unless patientdate ==0
    @patients_by_birthmonth= Patient.find_by_birthmonth(patientmonth) unless patientmonth ==0
    @patients_by_birthyear= Patient.find_by_birthyear(patientyear) unless patientyear ==0
       
    if @patients_by_birthday !=nil and @patients_by_birthmonth !=nil and @patients_by_birthyear !=nil
       @search_result_by_other_detail=@patients_by_birthday & @patients_by_birthmonth & @patients_by_birthyear
    end
    if  @patients_by_birthday ==nil and @patients_by_birthmonth ==nil and @patients_by_birthyear !=nil
        @search_result_by_other_detail= @patients_by_birthyear
    end
    if  @patients_by_birthday ==nil and @patients_by_birthmonth !=nil and @patients_by_birthyear ==nil
        @search_result_by_other_detail= @patients_by_birthmonth
    end
    if  @patients_by_birthday !=nil and @patients_by_birthmonth ==nil and @patients_by_birthyear ==nil
        @search_result_by_other_detail= @patients_by_birthday
    end
        
    if  @patients_by_birthday !=nil and @patients_by_birthmonth !=nil and @patients_by_birthyear ==nil
        @search_result_by_other_detail= @patients_by_birthmonth & @patients_by_birthday
    end
    if  @patients_by_birthday !=nil and @patients_by_birthmonth ==nil and @patients_by_birthyear !=nil
        @search_result_by_other_detail= @patients_by_birthday & @patients_by_birthyear
    end
    if  @patients_by_birthday ==nil and @patients_by_birthmonth !=nil and @patients_by_birthyear !=nil
        @search_result_by_other_detail= @patients_by_birthmonth & @patients_by_birthyear
    end
    if  @patients_by_birthday ==nil and @patients_by_birthmonth ==nil and @patients_by_birthyear !=nil
        @search_result_by_other_detail= @patients_by_birthday & @patients_by_birthmonth
    end
    if  @patients_by_birthday ==nil and @patients_by_birthmonth !=nil and @patients_by_birthyear !=nil
        @search_result_by_other_detail= @patients_by_birthmonth & @patients_by_birthyear
    end
    if  @patients_by_birthday !=nil and @patients_by_birthmonth ==nil and @patients_by_birthyear !=nil
        @search_result_by_other_detail= @patients_by_birthday & @patients_by_birthyear
    end

    empty_search =@search_result_by_other_details.empty?
    search_result__national_id= @search_result_by_other_details_national_id.empty?
    search_result_by_date_estimate=Array.new
    search_result_by_date_estimate =  Patient.find_by_age(estimate,patientyear) unless estimate == "" or  patientyear == 0
    estimate_empty=search_result_by_date_estimate.empty?
    if estimate_empty==false
       @search_result_by_other_detail=search_result_by_date_estimate
    end
    
    empty=@search_result_by_other_detail.empty?
    empty2=@search_result_by_other_details.empty?
    if empty==false
      if empty2 ==false
        @search_result_by_other_details=@search_result_by_other_details & @search_result_by_other_detail
      else
        @search_result_by_other_details= @search_result_by_other_detail    
      end 
    end

    empty=@search_result_by_other_details.empty?
    if search_result__national_id==false and empty==false
       @search_result_by_other_details=@search_result_by_other_details & @search_result_by_other_details_national_id    
    end
    if search_result__national_id==false and empty==true
       @search_result_by_other_details=@search_result_by_other_details_national_id
    end   
        
    gender_empty=@search_result_by_other_details.empty?
    if gender_empty ==false
       @search_result_by_other_details.delete_if{|patient| patient.gender != params[:patient_gender]} unless @search_result_by_other_details.nil? or params[:patient_gender] == ""
    else
       @search_result_by_other_details=  Patient.find_all_by_gender(params[:patient_gender]) if params[:patient_gender] !=""
    end
     
     otherdetails_empty=@search_result_by_other_details.empty?         
     if otherdetails_empty==false
        @search_result_by_other_details = @search_result_by_other_details & Patient.find_by_residence(params[:residence]) unless @search_result_by_other_details.nil? or params[:residence]==""
     else
       @search_result_by_other_details = Patient.find_by_residence(params[:residence]) unless @search_result_by_other_details.nil? or params[:residence]==""
     end  
     
     otherdetails_empty=@search_result_by_other_details.empty?
     if otherdetails_empty==false
        @search_result_by_other_details = @search_result_by_other_details & Patient.find_by_birth_place(params[:birth_place]) unless @search_result_by_other_details.nil? or params[:birth_place]==""
     else
       @search_result_by_other_details = Patient.find_by_birth_place(params[:birth_place]) unless @search_result_by_other_details.nil? or params[:birth_place]==""
     end   
         
    @empty_patients_by_other_details = @search_result_by_other_details.empty?    
    
    if @empty_patients_by_name ==false and @empty_patients_by_other_details ==false
       both_results=  @patients_by_name & @search_result_by_other_details
       @patients_by_name=both_results 
       @search_result_by_other_details=both_results 
    end
   
     @empty_patients_by_name=@patients_by_name.empty?
     @empty_patients_by_other_details=@search_result_by_other_details.empty?

    
     if national_id.to_s.length >0  and  @empty_patients_by_name ==true and  @empty_patients_by_other_details==true 
        @nationalid=national_id
        id_search_result = chk_national_id_validity(@national_id)
        @search_result=id_search_result
     end

# if there are any patients found by name execute the following code
    if @empty_patients_by_name ==false  
         if @empty_patients_by_other_details==false  
           @used_both_name_and_other_details=true
         else
           @used_both_name_and_other_details=false 
         end   
       @patients= @patients_by_name 
    end
    if @empty_patients_by_other_details ==false
       if  @empty_patients_by_name ==true
           @no_names_used=true
       end
       @patients= @search_result_by_other_details
    end
    if  @empty_patients_by_name ==true and  @empty_patients_by_other_details==true and  @patients.nil?
       render :text => @search_result 
    else
       render :partial => 'patients', :locals => {:mode => params[:mode]}
    end

  end

  def chk_national_id_validity(number)
    valid=number.match("P")
    index=number.index("P")

    chk_id=number.strip[1..-2]
    checked_id=PatientIdentifier.calculate_checkdigit(chk_id)
    if checked_id.to_s == number[-1..-1]
       id_search_result="patient not found"
    else
       id_search_result="check digit not matching"
    end
                                                              
    if valid==nil or index !=0 or number.length !=13
      id_search_result="Invalid Id"  
    end
    return id_search_result
  end

  def print_filing_numbers
    output = ""
    #Patient.find(:all).sort{|a,b|a.family_name <=> b.family_name}.each{|pat|output += "#{pat.family_name},#{pat.given_name},#{pat.filing_number}<br/>"}
    output = Patient.find(:all).each{|pat|output += "#{pat.family_name},#{pat.given_name},#{pat.filing_number}<br/>"}
    render :text => output
  end

  def validate_weight_height 
     date_started_art = Time.now()
     date_started_art=Date.strptime(params[:dateValue], "%d/%m/%Y").to_time unless params[:dateValue].nil?

     patient = Patient.find(session[:patient_id])

     patient_age_in_months_when_started= ((date_started_art-patient.birthdate.to_time)/1.month).floor
      
     @min_weight = ""
     @max_weight = ""
     @min_height = ""
     @max_height = ""
     @min_weight = WeightHeight.min_weight(patient.gender,patient_age_in_months_when_started)
     @max_weight = WeightHeight.max_weight(patient.gender,patient_age_in_months_when_started)
     @min_height = WeightHeight.min_height(patient.gender,patient_age_in_months_when_started)
     @max_height = WeightHeight.max_height(patient.gender,patient_age_in_months_when_started)
     render :text => "{min_weight:" + @min_weight.to_s + ", max_weight:" + @max_weight.to_s + ", min_height: "+ @min_height.to_s + ", max_height:" + @max_height.to_s + "}"  
     return                                      
  end
  
  def mastercard_modify
    # make sure we have a patient
    unless session[:patient_program].blank?
      patient_obj = Patient.find(params[:id])
      @patient_id = patient_obj.id
    else
      patient_obj = Patient.find(session[:patient_id]) rescue nil
      if patient_obj.blank? and !params[:id].blank?
        patient_obj = Patient.find(params[:id]) rescue nil 
      end
      redirect_to :action => "search" and return if patient_obj.blank?
    end
    
    # GET
    if request.method == :get    
      # find the field to modify
      field = params[:field]
      @patient_or_guardian = "patient"
      case field
        when "name"
          @given_name = patient_obj.given_name
          @family_name = patient_obj.family_name
          #@other_names = patient_obj.other_names
          #@other_name = @other_names[1] unless @other_names.empty?
          unless session[:patient_program].blank?
            render :partial => "mastercard_modify_name" and return
          else
            render :partial => "mastercard_modify_name", :layout => true and return
          end  
        when "age"
          patient_date = patient_obj.birthdate.to_date.to_s unless patient_obj.birthdate.nil?
          @patient_birthyear= patient_date.strip[0..3]  unless patient_date.nil? 
          @patient_birthmonth= patient_date.strip[5..6].to_i unless patient_date.nil?
          @patient_birthdate= patient_date.strip[8..9]  unless patient_date.nil?
          unless session[:patient_program].blank?
            render :partial => "mastercard_modify_age" and return
          else  
            render :partial => "mastercard_modify_age", :layout => true and return
          end  
        when "sex"
          @patient_sex = patient_obj.gender
          unless session[:patient_program].blank?
            render :partial => "mastercard_modify_sex" and return
          else
            render :partial => "mastercard_modify_sex", :layout => true and return
          end
        when "init_ht"
          @init_ht = patient_obj.observations.find_first_by_concept_name("Height").value_numeric unless  patient_obj.observations.find_first_by_concept_name("Height").nil?

          @field = Field.find_by_name "Height"          
          @attributes = Hash.new
          @attributes["validationRule"] = "[0-9]+\\.[0,5]$"
          @attributes["validationMessage"] = "You must enter a decimal, either 0 or 5 (for example 160.0"
          @attributes["min"] = WeightHeight.min_height(patient_obj.gender,patient_obj.age_in_months) rescue 25
          @attributes["max"] = WeightHeight.max_height(patient_obj.gender,patient_obj.age_in_months) rescue 300
          @attributes["absoluteMin"] = 25
          @attributes["absoluteMax"] = 300
    			@optional = "false"
          
          unless session[:patient_program].blank?
            render :partial => "mastercard_modify_init_ht" and return
          else  
            render :partial => "mastercard_modify_init_ht", :layout => true and return
          end
        when "init_wt"
          @init_wt = patient_obj.observations.find_first_by_concept_name("Weight").value_numeric unless  patient_obj.observations.find_first_by_concept_name("Weight").nil?

          @field = Field.find_by_name "Weight"          
          @attributes = Hash.new
          @attributes["validationRule"] = "[0-9]+\\.[0-9]$"
          @attributes["validationMessage"] = "You must enter a decimal between 0 and 9 (for example: 54<b>.6</b>"
          @attributes["min"] = WeightHeight.min_weight(patient_obj.gender,patient_obj.age_in_months) rescue 1
          @attributes["max"] = WeightHeight.max_weight(patient_obj.gender,patient_obj.age_in_months) rescue 150
          @attributes["absoluteMin"] = 1
          @attributes["absoluteMax"] = 150
    			@optional = "false"

          unless session[:patient_program].blank?
            render :partial => "mastercard_modify_init_wt" and return
          else
            render :partial => "mastercard_modify_init_wt", :layout => true and return
          end
        when "location"
          #city_village
          @residence = patient_obj.physical_address           
          unless session[:patient_program].blank?
            render :partial => "mastercard_modify_location" and return
          else
            render :partial => "mastercard_modify_location", :layout => true and return
          end
        when "address"
          #physical address identifier
          @physical_address = patient_obj.patient_location_landmark 
          unless session[:patient_program].blank?
            render :partial => "mastercard_modify_address" and return
          else
            render :partial => "mastercard_modify_address", :layout => true and return
          end  
        when "occupation"
          @occupation = patient_obj.occupation
          unless session[:patient_program].blank?
            render :partial => "mastercard_modify_occupation" and return
          else
            render :partial => "mastercard_modify_occupation", :layout => true and return
          end    
        when "guardian"
          guardian_type = RelationshipType.find_by_name("ART Guardian")
          person = patient_obj.people[0]
          @patient_or_guardian = "guardian"
          @patient_first_name = patient_obj.art_guardian.given_name unless patient_obj.art_guardian.nil?
          @patient_surname = patient_obj.art_guardian.family_name unless patient_obj.art_guardian.nil?
          unless session[:patient_program].blank?
            render :action => "search", :mode => "guardian" ,:layout => false and return
          else
            render :action => "search", :mode => "guardian", :layout => true and return
          end  
        when "hiv_test"
          location_id = patient_obj.observations.find_first_by_concept_name("Location of first positive HIV test").value_numeric unless patient_obj.observations.find_first_by_concept_name("Location of first positive HIV test").nil?
          @hiv_test_location = Location.find(location_id).name unless location_id.nil?
          @hiv_test_date = patient_obj.observations.find_by_concept_name("Date of positive HIV test").first.value_datetime.strftime("%d %B %Y")unless patient_obj.observations.find_by_concept_name("Date of positive HIV test").empty?
          render :partial => "mastercard_modify_hiv_test", :layout => true and return
        when "previous_arv_number"
            if  session[:patient_program] == "HIV" 
              current_numbers = []
              PatientIdentifier.find(:all,
              :conditions=>['identifier_type=? and voided=0',PatientIdentifierType.find_by_name("Previous ARV number").id],
              :group => 'identifier').collect{|d|
                next if d.identifier.match(/[0-9]+/).blank?
                current_numbers << d.identifier 
              } rescue nil
              @current_numbers = current_numbers.sort.to_json rescue []
              @from_create_patient = true if params[:show_previous_visits] == "true"
            end
            render :partial => "mastercard_modify_previous_arv_number" and return
        when "arv_number"
          unless session[:patient_program].blank?
            if  session[:patient_program] == "HIV" 
              current_numbers = []
              PatientIdentifier.find(:all,
              :conditions=>['identifier_type=? and voided=0',PatientIdentifierType.find_by_name("Arv national id").id],
              :group => 'identifier').collect{|d|
                next if d.identifier.match(/[0-9]+/).blank?
                current_numbers << d.identifier #.match(/[0-9]+/)[0].to_i 
              } rescue nil
              @current_numbers = current_numbers.sort.to_json rescue []
              @from_create_patient = true if params[:show_previous_visits] == "true"
            else
              current_numbers = []
              PatientIdentifier.find(:all,
              :conditions=>['identifier_type=? and voided=0',PatientIdentifierType.find_by_name("TB treatment ID").id],
              :group => 'identifier').collect{|d|
                next if d.identifier.match(/[0-9]+/).blank?
                current_numbers << d.identifier #.match(/[0-9]+/)[0].to_i 
              } rescue nil
              @current_numbers = current_numbers.sort.to_json rescue []
            end
            render :partial => "mastercard_modify_arv_number" and return
          else  
            current_numbers = []
            arv_code = Location.current_arv_code
            PatientIdentifier.find(:all,
            :conditions=>['identifier_type=? and voided=0',PatientIdentifierType.find_by_name("Arv national id").id],
            :group => 'identifier').collect{|d|
              next if d.identifier.match(/[0-9]+/).blank?
              next if d.identifier.match(/#{arv_code}/i).blank?
              current_numbers << d.identifier.match(/[0-9]+/)[0].to_i 
            } rescue nil
            @current_numbers = current_numbers.sort.to_json rescue nil
            render :partial => "mastercard_modify_arv_number", :layout => true and return
          end  
        when "ta"
          @ta = patient_obj.traditional_authority
          unless session[:patient_program].blank?
            render :partial => "mastercard_modify_ta" and return
          else
            render :partial => "mastercard_modify_ta", :layout => true and return
          end  

        when "first_line_date"
          # TODO not done yet in mastercard
        when "alt_arv1"
          # TODO not done yet in mastercard
        when "alt_arv2"
          # TODO not done yet in mastercard

        # These are edited as back of mastercard items:  
        #when "reason_for_arv"
        #when "ptb"
        #when "eptb"
        #when "kaposi_sarcoma"
      end        
    end  

    # POST    
    if request.method == :post    
      field = params[:field]
      case field
        when "arv_number"
          patient_obj.arv_number = params[:arv_number]
        when "previous_arv_number"
          patient_obj.previous_arv_number = params[:arv_number]
        when "name"
          patient_name = PatientName.new
          patient_name.given_name = params[:given_name] if params[:given_name]
          patient_name.family_name = params[:family_name] if params[:family_name]
          #patient_name.patient = patient_obj
          #patient_obj.update_name!(patient_name, "Modifying mastercard")       
         
          patient_obj.set_name(patient_name.given_name, patient_name.family_name) unless patient_obj.name == "#{patient_name.given_name} #{patient_name.family_name}"
        when "age" 
          estimate = set_date()          
          if  params[:patient_year] == "Unknown" and patient_estimated_birthyear == ""
            flash[:error] = 'Estimate patient age before saving!!'
            redirect_to :action => "mastercard"
            return
          end          
          patient_birthdate = params[:patient_day] + "-" + params[:patient_month] + "-" + params[:patient_year]
          patient_birthdate =  patient_birthdate.to_date rescue nil#.to_s
          patient_obj.birthdate = patient_birthdate
          if estimate == true
            patient_obj.birthdate_estimated = estimate
          end
        when "sex"  
          # if we were using person records we would void the person?
          patient_obj.gender = params[:patient][:gender]
        when "init_ht"
          # TODO handle nil
          first_obs = patient_obj.observations.find_first_by_concept_name("Height")
          unless first_obs.nil? 
            first_obs.void! "Modifying mastercard"
#            session[:encounter] = first_obs.encounter
#            parse_observations(params)
            first_obs.encounter.parse_observations(params) unless first_obs.encounter.nil?
          end
        when "init_wt"  
          # TODO handle nil
          first_obs = patient_obj.observations.find_first_by_concept_name("Weight")
          unless first_obs.nil? 
            first_obs.void! "Modifying mastercard"
#            session[:encounter] = first_obs.encounter
#            parse_observations(params)
            first_obs.encounter.parse_observations(params) unless first_obs.encounter.nil?
          end
        when "location"
          PatientAddress.create(patient_obj.id,params[:patientaddress][:city_village])
        when "address"
          patient_obj.reason = "Modifiying Mastercard" 
          patient_obj.patient_location_landmark = params[:physical_address][:identifier]
        when "occupation"  
          patient_obj.reason = "Modifiying Mastercard" 
          patient_obj.occupation = params[:patient][:occupation]
        when "tb_number" 
          patient_obj.reason = "Modifiying Mastercard" 
          patient_obj.tb_number = params[:tb_number]
        when "ta" 
          patient_obj.reason = "Modifiying Mastercard" 
          patient_obj.traditional_authority= params[:ta][:identifier]
      end  
      if patient_obj.save      
        if session[:patient_program].blank?
          redirect_to :action => 'mastercard'
        else
          if session[:patient_program] == "HIV"
            redirect_to :action => 'retrospective_data_entry',
              :id => @patient_id,:visit_added => "true"
          else  
            redirect_to :action => 'tb_card',:id => @patient_id
          end  
        end  
      else
        flash[:error] = 'Could not save patient name'
        if session[:patient_program].blank?
          redirect_to :action => 'error'              
        else
          if session[:patient_program] == "HIV"
            redirect_to :action => 'retrospective_data_entry',
              :id => @patient_id,:visit_added => "true"
          else  
            redirect_to :action => 'tb_card',:id => @patient_id
          end  
        end  
      end  
      return
    end              
    
  end

  def registered_at_clinic 
      starting_year=params[:starting_year]
      starting_month=params[:starting_month] 
      starting_day=params[:starting_date]

      ending_year=params[:ending_year]
      ending_month=params[:ending_month]
      ending_day=params[:ending_date]
      patient_type= params[:gender]
        
      unless starting_year.nil? and starting_month.nil? and starting_day.nil? and ending_year.nil? and  ending_month.nil? and ending_day.nil? then
        start_date=starting_year.to_s + "-" + starting_month.to_s + "-" + starting_day.to_s 
        end_date=ending_year.to_s + "-" + ending_month.to_s + "-" + ending_day.to_s
        @patients= Patient.find_patients_adults(patient_type,start_date,end_date)  if  start_date.to_date.strftime("%Y-%m-%d") <= end_date.to_date.strftime("%Y-%m-%d") and patient_type !=""
        @start_end_dates=" from " + start_date.to_date.strftime("%Y-%m-%d") + " to " + end_date.to_date.strftime("%Y-%m-%d") if start_date < end_date and patient_type !=""
      end  
       
      @years=  params[:gender]
      render(:layout => "layouts/patient_report")
     # render(:layout => false)
  end

  
=begin
  def report_menu
   render(:layout => "layouts/patient_report")
  end
=end  

  def update_outcome
    #need to include estimation indicator for instances where the outcome date is estimated.
    @needs_date_picker = true
    unless session[:patient_program].blank?
      @patient = Patient.find(params[:id])
      if session[:patient_program] == "HIV"
        Location.set_current_location = Location.find_by_name(params[:selected_site])
      end
    else  
      @patient = Patient.find(session[:patient_id])
    end  
    give_drugs_encounters = @patient.encounters.find_by_type_name("Give drugs")
    unless give_drugs_encounters.nil? or give_drugs_encounters.empty?
      @end_date = give_drugs_encounters.last.encounter_datetime    
		else
	    @end_date = Date.today					
		end
    if request.post? || params[:adding_visit] == "true"
      if not params[:adding_visit] == "true"
        unless params[:location][:location_id].nil? #save location that patient has been transfered to
          set_transfer_location
        end
      end
      if (params[:patient_day] == "Unknown" or params[:patient_month] == "Unknown" or params[:patient_year] == "Unknown")
	      encounter_date = estimate_outcome_date(@end_date,session[:encounter_datetime],params[:patient_year],params[:patient_month],params[:patient_day]) 
        estimate = true
      else
        encounter_date = params[:patient_day].to_s + "-" + params[:patient_month].to_s + "-" + params[:patient_year].to_s
      end

      unless session[:patient_program].blank?
          encounter_date = params[:encounter_date]
      end
        
      update_outcome_encounter = EncounterType.find_or_create_by_name("Update outcome")
      #The following code will void all possible outcomes for a patient on a given date before create a new one
      outcome_concept = Concept.find_by_name("Outcome")
      outcome_ids = []
      outcome_ids << outcome_concept.id
      outcome_ids << Concept.find_by_name("Continue treatment at current clinic").id
      outcome_ids << Concept.find_by_name("Continue ART").id
      current_outcomes_for_day = Observation.find(:all,
                                                  :conditions =>["concept_id IN (?) AND DATE(obs_datetime)=? 
                                                  AND patient_id=? AND voided=0",outcome_ids,
                                                  session[:encounter_datetime].to_date,@patient.id])
      current_outcomes_for_day.each{|obs|
        obs.voided = 1
        obs.voided_by = User.current_user.id
        obs.date_voided = Time.now()
        obs.void_reason = "patient has new outcome status"
        obs.save
      }
      #_______________________________________________________________________________

      encounter = Encounter.new
      observation = Observation.new
      encounter.type = update_outcome_encounter
      encounter.patient_id = @patient.patient_id
      observation.patient_id = @patient.patient_id
      observation.concept_id = outcome_concept.concept_id
      observation.value_coded = Concept.find_by_name(params[:outcome]).concept_id
      observation.value_modifier = "estimated" if estimate == true
      case params[:outcome]
        when "Died"
	        observation.obs_datetime = encounter_date.to_date 
          @patient.death_date = encounter_date.to_date
          #@patient.cause_of_death = params[:patient][:cause]
          @patient.save
        when "ART Stop"
          observation.obs_datetime = encounter_date.to_date 
        else
          observation.obs_datetime = session[:encounter_datetime]
      end
      
      encounter.provider_id = User.current_user.user_id
      encounter.encounter_datetime = session[:encounter_datetime]
      observation.location_id = session[:encounter_location] if session[:encounter_location] # encounter_location gets set in the session if it is a transfer in
      encounter.save
      observation.encounter = encounter
      if observation.save 
        flash[:notice] = "Patient outcome updated to:#{params[:outcome]}"
        if params[:adding_visit] == "true"
          redirect_to :controller => "drug_order",:action => "create",:encounter_date => params[:encounter_date],
          :dispensed => params[:dispensed],:adding_visit => "true",:id => @patient.id ; return
        end  
        
        #print out transfer out label
        if request.post?
          location_name = params[:location][:location_id]
          print_and_redirect("/label/transfer_out_label/?id=#{@patient.id}&location=#{location_name}", "/patient/menu") unless location_name.blank?
          redirect_to :action =>"menu" if location_name.blank?
          return
        end
        redirect_to :action =>"menu"
      end
    end
  end


  def set_transfer_location
     if params[:patient_day] == "Unknown" or params[:patient_month] == "Unknown" or params[:patient_year] == "Unknown"
	     encounter_date = estimate_outcome_date(@end_date,session[:encounter_datetime],params[:patient_year],params[:patient_month],params[:patient_day]) 
      estimate = true
      else
        encounter_date = params[:patient_day].to_s + "-" + params[:patient_month].to_s + "-" + params[:patient_year].to_s
      end
    encounter = Encounter.new
    observation = Observation.new
    encounter.type = EncounterType.find_or_create_by_name("Update outcome")
    encounter.patient_id = session[:patient_id]
    #save location that patient has been transfered to
    observation.patient_id = @patient.patient_id
    observation.concept_id = Concept.find_by_name("Transfer out destination").concept_id
    observation.value_numeric = Location.find_or_create_by_name(params[:location][:location_id]).id

  end
   
  def arv_registration_number
      raise "This method is no longer used"
      prefix_and_version_number="XYZ "
      current_arv_numbers=Array.new
# Only 4000 arv numbers allowed at MPC
      possible_arv_numbers=Array.new(3999){|i|prefix_and_version_number +  (i + 1).to_s}
      current_arv_numbers=PatientIdentifier.find_all_by_identifier_type(PatientIdentifierType.find_by_name("Arv national id").patient_identifier_type_id).collect{|identifiers|identifiers.identifier} unless PatientIdentifier.find_all_by_identifier_type(PatientIdentifierType.find_by_name("Arv national id").patient_identifier_type_id).nil?
      next_arv_number=(possible_arv_numbers - current_arv_numbers).first
      @next_arv_number=next_arv_number[4..-1]
  end

  def create_arv_number
  prefix_and_version_number = Location.current_location.description.split(":")[1] rescue ""
  passed_number = params[:arv_number].match(/\d+/)[0]
  arv_number =  prefix_and_version_number + " " + passed_number
  current_arv_numbers = PatientIdentifier.find_all_by_identifier_type(PatientIdentifierType.find_by_name("Arv national id").patient_identifier_type_id)
  current_arv_numbers = current_arv_numbers.collect{|identifiers|identifiers.identifier} unless current_arv_numbers.blank?
  #checking if the arv number is valid by checking if number submitted is already assign to another patient
  old_array_len = current_arv_numbers.length
#if the arv_number is valid,it will be added to the existing ones
  current_arv_numbers = current_arv_numbers | [arv_number]
  new_array_len=current_arv_numbers.length
    if request.post? and (new_array_len > old_array_len)
      @arv_number= PatientIdentifier.new()
      @arv_number.patient = Patient.find(session[:patient_id])
      @arv_number.identifier_type = PatientIdentifierType.find_by_name("Arv national id").patient_identifier_type_id
      @arv_number.identifier=arv_number

      unless @arv_number.save
        flash[:error] = 'Could not create patients arv number'
        redirect_to :action => 'arv_registration_number'
      else
        flash[:notice] = "Patient arv number is: #{arv_number}"
        redirect_to :action =>"menu"
      end
    else
      flash[:notice] = "Arv number '#{arv_number}' already exist"
      redirect_to :action =>"arv_registration_number"
    end  
  end
  
  def summary
    visit_time = session[:encounter_datetime]
    @visit_date = visit_time.to_s.to_date
    @patient = Patient.find(session[:patient_id])
    redirect_to :action =>"menu" and return unless @patient.art_patient?
   
    @user = User.find(session[:user_id])
    @next_forms = @patient.next_forms(session[:encounter_datetime])
    unless @next_forms.nil?
      @next_activities = @next_forms.collect{|f|f.type_of_encounter.name}.uniq
    end

    @identifier = ""
    identifier_type = GlobalProperty.find_by_property("identifier_type_for_patient_summary").property_value rescue "National id"
    
    if identifier_type.match(/filing/i)
      @identifier = @patient.filing_number
      @identifier = @identifier[0..4]  + " " + Patient.print_filing_number(@identifier) rescue ""
    else
      @identifier = PatientIdentifier.find(:first,
                                     :conditions =>["voided=0 AND patient_id=? AND identifier_type=?",
                                     @patient.id,
                                     PatientIdentifierType.find_by_name(identifier_type).id]).identifier rescue ""
    end

    unless @patient.nil? or @next_activities.nil? or @next_activities.length < 1 
     if @next_activities.length >= 1 
      @next_task = @next_activities.join("<br/>")
     else 
      @next_task = "visit complete" 
     end 
   
    end

    last_encounter = @patient.encounters.find(:first, :order => 'encounter_datetime DESC', 
                             :joins => :type, 
                             :conditions => ['encounter_type NOT IN (?) AND DATE(encounter_datetime) < ?', 
                                             EncounterType.find_all_by_name(
                                               ['Move file from dormant to active', 
                                                'Barcode scan']).map(&:id), 
                                             @visit_date
                                            ]
    ) rescue nil

    @last_visit_date = last_encounter.encounter_datetime.to_date rescue @visit_date
    
    side_effects = ["Peripheral neuropathy", "Hepatitis", "Skin rash", "Lactic acidosis", "Lipodystrophy", "Anaemia", "Other side effect"]
    @current_side_effects = ""
    @previous_side_effects = ""
    
    @previous_side_effects = @patient.observations.find(:all, 
                                                        :conditions => ['value_coded IN (?) AND voided = 0 AND obs_datetime < ?', 
                                                                        407, @visit_date]
                                                       ).map(&:concept).map(&:name).join(', ') rescue ''
    
    @current_side_effects = @patient.observations.find(:all, 
                                                       :conditions => ['value_coded IN (?) AND voided = 0 AND obs_datetime BETWEEN ? AND ?', 
                                                                        407, @visit_date.to_time, "#@visit_date} 23:59:59"]
                                                      ).map(&:concept).map(&:name).join(', ') rescue ''

    last_visit_drug_orders = @patient.previous_art_drug_orders(@last_visit_date)            
    @previous_art_drug_orders = last_visit_drug_orders.collect{|drug_order|drug_order.drug.name}.uniq unless last_visit_drug_orders.blank?

    @last_regimen_observation = @patient.observations.find_last_by_concept_name("ARV regimen")

    hiv_reception_encounter =  @patient.encounters.find_by_type_name_and_date("HIV Reception",session[:encounter_datetime])
     
    patient_present = hiv_reception_encounter.first.observations.find_by_concept_name("Patient present") rescue nil 
    guardian_present = hiv_reception_encounter.first.observations.find_by_concept_name("Guardian present") rescue nil

    unless (hiv_reception_encounter.blank? or hiv_reception_encounter.first.observations.blank?)      
      patient_visit = true if patient_present.first.answer_concept.name == "Yes" rescue false          
      guardian_visit = true if guardian_present.first.answer_concept.name == "Yes" rescue false
      patient_and_guardian_visit = true if patient_visit and guardian_visit
    end 

    if patient_and_guardian_visit
     @visit_type = "Guardian and patient visit"
    elsif guardian_visit
     @visit_type = "Guardian only visit"
    elsif patient_visit
     @visit_type = "Patient only visit"
    else
     @visit_type = ""
    end

    @prescription = @patient.prescriptions(session[:encounter_datetime]).collect{|p|p.drug.name + '</br>'}.uniq

    @current_height  = @patient.current_height(@visit_date) 
    @previous_height = @patient.previous_height(@visit_date)

    @current_weight = @patient.current_visit_weight(@visit_date)  
    @previous_weight = @patient.previous_weight(@visit_date) 

    unless @current_weight.blank? or @current_height.blank?
      @bmi = (@current_weight/(@current_height*@current_height)*10000)
    end   

    unless @previous_height.blank? or @previous_weight.blank?
      @previous_bmi = (@previous_weight/(@previous_height*@previous_height)*10000)
    end 

    needs_cd4_count_reminder = GlobalProperty.find_by_property("show_cd4_count_reminder").property_value rescue "false"

    user_roles = @user.roles
    if needs_cd4_count_reminder == 'true' and (user_roles.include?("Nurse") || 
                                               user_roles.include?("Clinician") || 
                                               user_roles.include?("superuser"))
      @patient_needs_cd4_count = @patient.needs_cd4_count?(@visit_date)
      lab_trail = GlobalProperty.find_by_property("show_lab_trail").property_value rescue "false"
      @show_lab_trail = lab_trail == 'false' ? false : true
    else
      @patient_needs_cd4_count = false
    end

    @number_of_months = 0
    @number_of_months = ((session[:encounter_datetime] - @patient.date_started_art)/1.month).floor unless @patient.date_started_art.nil?

    render:layout => false
  end

=begin  
  def paper_mastercard
    render(:layout => false)
  end
=end
  
  def create_filing_number
    patient = Patient.find(session[:patient_id])
    patient.set_filing_number
    archived_patient = patient.patient_to_be_archived
    unless archived_patient.blank?
      message = printing_message(patient,archived_patient,true)
      print_and_redirect("/label/filing_number/#{patient.id}", "/patient/menu",message,next_button=true)
      return
    end
    flash[:notice] = "New filing number created!!"
    redirect_to :action =>"menu"
  end
  
  def encounters
    if session[:patient_program].blank?
      @patient = Patient.find(session[:patient_id])
    else
      @patient = Patient.find(params[:id])
      encounter_datetime = params[:date].to_date
      session[:encounter_datetime] = encounter_datetime
    end    
    
    user = User.current_user
    @user_is_superuser = user.user_roles.collect{|r|r.role.role}.include?("superuser")
    @show_other_forms = @user_is_superuser || user.has_role('Clinician')

    barcode_scan_type_id = EncounterType.find_by_name('Barcode scan').id
    @day_encounters = @patient.encounters.find(:all, 
                                               :conditions => ['DATE(encounter_datetime) = DATE(?) 
                                               AND encounter_type != ?',session[:encounter_datetime],
                                               barcode_scan_type_id]) if @user_is_superuser
    @day_encounters = @patient.encounters.find(:all, 
                                               :conditions => ['creator = ? AND 
                                               DATE(encounter_datetime) = DATE(?) AND encounter_type != ?',
                                               user.id, session[:encounter_datetime], barcode_scan_type_id]
                                              ) unless @user_is_superuser

    @other_encounter_types = [1,2,3,5,6,7] - @patient.encounters.find_by_date(
                                               session[:encounter_datetime].to_date
                                             ).map(&:encounter_type)
    unless session[:patient_program].blank?
      session[:encounter_datetime] = nil
      @encounter_datetime = encounter_datetime
    end    
    render(:layout => false)
  end
  
  def set_new_filing_number
   barcode = params[:barcode]
   barcode_cleaned = barcode.gsub(/(-| |\$)/,"") unless barcode.blank? #remove spaces and dashes
  
   @patient = PatientIdentifier.find(:first, :conditions => ["identifier = ? OR identifier = ?", barcode, barcode_cleaned]).patient rescue nil
   #@patient = Patient.find_by_national_id(barcode_cleaned).last unless barcode_cleaned.blank?
   unless @patient.blank?
   @active_patient = @patient.active_patient?
    if @patient.filing_number.blank?
     if @active_patient
       @patient.set_filing_number
       archived_patient = @patient.patient_to_be_archived
       unless archived_patient.blank?
        message = printing_message(@patient,archived_patient)
        print_and_redirect("/label/filing_number_and_national_id/#{@patient.id}", "/patient/set_new_filing_number/?barcode=#{@patient.national_id}",message,next_button=true)
        return
       end
     else
       @patient.set_archive_filing_number
     end    
     print_and_redirect("/label/filing_number_and_national_id/#{@patient.id}", "/patient/set_new_filing_number/?barcode=#{@patient.national_id}")
     flash[:notice] = 'Created new filing number'
     return
    end
   else
    flash[:error] = "Could not find a patient with national id:#{barcode_cleaned}"
   end
   render :layout => false
  end   
  
  def lab_results
  # render :text => params[:id]
   #return
   @patient =  Patient.find(session[:patient_id])
   @lab_results =  LabSample.cd4_trail(@patient.id_identifiers)
   render :layout => false
  end

  def lab_menu
   @patient =  Patient.find(session[:patient_id])
   @available_lab_results = @patient.available_lab_results
   show_enter_lab_results = GlobalProperty.find_by_property("show_enter_lab_results").property_value rescue "false"
   @show_enter_lab_results = false
   if show_enter_lab_results == "true"
    @show_enter_lab_results = true
   end  
   render :layout => false
  end

  def detail_lab_results
   @patient =  Patient.find(session[:patient_id])
   detail_lab_results = @patient.detail_lab_results(params[:id])
   @detail_lab_results = @patient.detailed_lab_results_to_display(detail_lab_results)
   @test_results = params[:id].gsub("_"," ")
   render :layout => false
  end

  def detail_lab_results_graph
   @results = params[:id].to_s || ''
   @results = @results.split(':').enum_slice(2).map   
   @results = @results.each {|result| result[0] = result[0].to_date}.sort_by{|result| result[0]}
   @results.each{|result| @graph_max = result[1].to_f if result[1].to_f > (@graph_max || 0)} 
   @graph_max ||= 0
   render :layout => false
  end

  def admin_menu
    @show_general_reception_stats = true if User.current_user.activities.include?("General Reception")
    render(:layout => "layouts/menu")
  end

  def duplicates
    @duplicates = Patient.duplicates(params[:attributes])
    render(:layout => "layouts/menu")
  end

  def duplicate_menu
    #render(:layout => "layouts/menu")
  end

  def list_by_visit_date
    @visit_date = Date.today
    @visit_date = params[:id].to_date unless params[:id].nil?
    session[:encounter_datetime] = @visit_date.to_time
    @encounters = Encounter.find(:all, :include => [:patient], :conditions => ["(DATE(encounter.encounter_datetime) = ?)", @visit_date])
    @patients = @encounters.collect{|encounter| encounter.patient unless encounter.name == "Barcode scan"}.uniq
    render :layout => false
  end

  def find_by_arv_number
    params[:id] = Location.current_arv_code + params[:arv_number]
    set_patient
    return
  end
   
  def merge
    arv_number = params[:id] unless params[:id].blank?
    patients = PatientIdentifier.find(:all, :conditions => ["identifier= ?", arv_number]).map(&:patient)
    if patients.blank? and params[:other]
      primary_patient = Patient.find(params[:id])
      secondary_patient = Patient.find(params[:other])
    else
    #need to determine which of the two patients has the most recent visit
    #that patient will be the active patient
      patient1_last_visit_date = patients[0].last_art_visit_date 
      patient2_last_visit_date = patients[1].last_art_visit_date
      primary_patient = nil
      secondary_patient = nil
      if patient1_last_visit_date.nil? and not patient2_last_visit_date.nil? 
        primary_patient = patients[1]
        secondary_patient = patients[0]
      elsif patient2_last_visit_date.nil? and not patient1_last_visit_date.nil?
        primary_patient = patients[0]
        secondary_patient = patients[1]
      end
      
      primary_patient = patient1_last_visit_date > patient2_last_visit_date ? patients[0] : patients[1] rescue nil if primary_patient.nil?
      secondary_patient = patient1_last_visit_date < patient2_last_visit_date ? patients[0] : patients[1] rescue nil if secondary_patient.nil?
      
      # use date_started_art if we still don't have our primary patient 
      if (primary_patient.nil? or secondary_patient.nil?)
        if patients[0].date_started_art and patients[1].date_started_art.nil?
          primary_patient = patients[0]
          secondary_patient = patients[1]
        elsif patients[1].date_started_art and patients[0].date_started_art.nil?
          primary_patient = patients[1]
          secondary_patient = patients[0]
        end
      end
    end
      
    Patient.merge(primary_patient.id,secondary_patient.id)

    redirect_to :controller => :reports, :action => 'duplicate_identifiers'     
  end
  
  def merge_all_patients
    if request.method == :post
      params[:patient_ids].split(":").each do | ids |
        master = ids.split(',')[0].to_i ; slaves = ids.split(',')[1..-1]
        ( slaves || [] ).each do | patient_id  |
          next if master == patient_id.to_i
          Patient.merge(master,patient_id.to_i)
        end
      end
      flash[:notice] = "Successfully merged patients"
    end
    redirect_to :action => "merge_show" and return
  end 

  def merge_patients
    master = params[:patient_ids].split(",")[0].to_i
    slaves = []
    params[:patient_ids].split(",").each{ | patient_id |
      next if patient_id.to_i == master
      slaves << patient_id.to_i
    }

    ( slaves || [] ).each do | patient_id  |
      Patient.merge(master,patient_id)
    end
    render :text => "true" and return
  end 

  def mastercard
    if User.current_user.activities.include?("General Reception")
      redirect_to :controller => "outpatient_report",:action => "dash_board" ; return
    end 
     
    if session[:patient_id].blank?
      if session[:show_patients_mastercards] || params[:id]
        @patient_ids = params[:id].to_s.strip rescue nil
        redirect_to :controller => "reports", :action => 'select_cohort' and return if @patient_ids.blank?

        patient = Patient.find(@patient_ids.split(",")[0].to_i) 
        @current_patient_index = "1 of #{@patient_ids.split(',').length}"
        @data = MastercardVisit.demographics(patient)
        @previous_visits = MastercardVisit.visits(patient)
        session[:current_mastercard_ids] = @patient_ids.split(",")
      else
        redirect_to :action => "search"
        return
      end
    else  
      patient_obj = Patient.find(session[:patient_id])
      patient_obj.reset_adherence_rates
      patient_obj.reset_outcomes
      @data = MastercardVisit.demographics(patient_obj)
      @previous_visits = MastercardVisit.visits(patient_obj)
    end
    
    render(:layout => "layouts/mastercard")
  end

  def demographics
    patient_ids = session[:current_mastercard_ids]
    current_patient = params[:patient_id]
    next_previous = params[:next_previous]
    
    next_patient_id = MastercardVisit.next_mastercard(current_patient,patient_ids,next_previous)
    patient = Patient.find(next_patient_id) 
    patient.reset_adherence_rates
    patient.reset_outcomes
    @current_patient_index = "#{(patient_ids.index(next_patient_id)) + 1} of #{patient_ids.length}"
    @data = MastercardVisit.demographics(patient)
    @previous_visits = MastercardVisit.visits(patient)
    session[:previous_visits] = @previous_visits
    session[:previous_data] = @data
    render :partial => "mastercard_demographics" and return
  end

  def current_mastercard_ids
    render :text => (session[:current_mastercard_ids].map{|x|x.to_i}).to_json and return
  end  


  def get_patient_id
    patient = Patient.find_by_arv_number(params[:arv_number])
    render :text => patient.id and return
  end

  def find_record
    patient_ids = session[:current_mastercard_ids]
    patient = Patient.find(params[:patient_id])
    next_patient_id = patient.id.to_s
    next_previous = params[:next_previous]
    
    #raise patient_ids.inspect
    #next_patient_id = MastercardVisit.next_mastercard(current_patient,patient_ids,next_previous)
    patient.reset_adherence_rates
    patient.reset_outcomes
    @current_patient_index = "#{(patient_ids.index(next_patient_id)) + 1} of #{patient_ids.length}"
    @data = MastercardVisit.demographics(patient)
    @previous_visits = MastercardVisit.visits(patient)
    session[:previous_visits] = @previous_visits
    session[:previous_data] = @data
    render :partial => "mastercard_demographics" and return
  end

  def next_card
    @previous_visits = session[:previous_visits] 
    @data = session[:previous_data] 
    session[:previous_visits] = nil
    session[:previous_visits] = nil
    render :partial => "mastercard_visits" and return
  end

  def previous_card
    @previous_visits = session[:previous_visits] 
    @data = session[:previous_data] 
    session[:previous_visits] = nil
    session[:previous_visits] = nil
    render :partial => "mastercard_visits" and return
  end

  def get_identifier
    patient = Patient.find_by_national_id(params[:id]).first rescue nil
    use_filing_numbers = GlobalProperty.find_by_property("use_filing_numbers").property_value rescue "false"
    if use_filing_numbers == "true" and patient
      render :text => patient.filing_number and return
    elsif use_filing_numbers == "false" and patient   
      render :text => patient.arv_number and return
    else  
      render :text => "" and return
    end  
  end

  def paper_mastercard
    user = User.current_user
    @username = user.username
    mastercard_image = user.user_properties.find_by_property('mastercard_image').property_value rescue ''
    if session[:patient_id] and mastercard_image.empty?
      mastercard_image = Patient.find(session[:patient_id]).image_arv_number + '-1' rescue '-'
    end
    @arv_number,@selected_page = mastercard_image.split('-')
    if @arv_number.blank?
      @files = []
      @pages = []
    else
      @files = Dir.glob(RAILS_ROOT + "/public/images/mc1/#{@arv_number}*jpg").map{|f| f.split('/').last}
      @pages = @files.map do |f|
        f =~ /-(\d+).jpg/
        $1
      end.sort
    end
    render :layout => false
  end

  def set_mastercard_page
    User.current_user.assign_mastercard_image(params[:id])
    render :text => ''
  end

  def current_mastercard_page
    user = User.current_user
    image = user.user_properties.find_by_property('mastercard_image').property_value rescue ''
    render :text => image
  end
 
  def search_all
    search_str = params[:search_str] ; side = params[:side]
    search_by_identifier = search_str.match(/[0-9]+/).blank? rescue false

    unless search_by_identifier
      patients = PatientIdentifier.find(:all, :conditions => ["voided = 0 AND (identifier LIKE ?)", 
      "%#{search_str}%"],:limit => 10).map{| p |p.patient}
    else
      given_name = search_str.split(' ')[0] rescue '' ; family_name = search_str.split(' ')[1] rescue ''
      patients = PatientName.find(:all , :conditions => ["voided = 0 AND family_name LIKE ? AND given_name LIKE ?",
      "#{family_name}%","%#{given_name}%"],:limit => 10).map{| p |p.patient}
    end

    @html = <<EOF
<html>
<head>
<style>
  .color_blue{
    border-style:solid;
  }
  .color_white{
    border-style:solid;
  }

  th{
    border-style:solid;
  }
</style>
</head>
<body>
<br/>
<table class="data_table">
EOF

      color = 'blue'
      patients.each do |patient|
        if color == 'blue'
          color = 'white'
        else
          color='blue'
        end
        @html+= <<EOF
<tr>
  <td class='color_#{color} patient_#{patient.id}' style="text-align:left;" onclick="setPatient('#{patient.id}','#{color}','#{side}')">Name:&nbsp;#{patient.name || '&nbsp;'}</td>
  <td class='color_#{color} patient_#{patient.id}' style="text-align:left;" onclick="setPatient('#{patient.id}','#{color}','#{side}')">Age:&nbsp;#{patient.age || '&nbsp;'}</td>
</tr>
<tr>
  <td class='color_#{color} patient_#{patient.id}' style="text-align:left;" onclick="setPatient('#{patient.id}','#{color}','#{side}')">Guardian:&nbsp;#{patient.art_guardian.name rescue '&nbsp;'}</td>
  <td class='color_#{color} patient_#{patient.id}' style="text-align:left;" onclick="setPatient('#{patient.id}','#{color}','#{side}')">ARV number:&nbsp;#{patient.arv_number || '&nbsp;'}</td>
</tr>
<tr>
  <td class='color_#{color} patient_#{patient.id}' style="text-align:left;" onclick="setPatient('#{patient.id}','#{color}','#{side}')">National ID:&nbsp;#{patient.print_national_id || '&nbsp;'}</td>
  <td class='color_#{color} patient_#{patient.id}' style="text-align:left;" onclick="setPatient('#{patient.id}','#{color}','#{side}')">TA:&nbsp;#{patient.traditional_authority || '&nbsp;'}</td>
</tr>
EOF
      end
      
      @html+="</table></body></html>"   
      render :text => @html ; return  
  end
  
  def merge_show
    session[:merging_patients] = nil
    @first_patient = Patient.find(params[:first_pat]) rescue nil
    @second_patient = Patient.find(params[:sec_pat]) rescue nil
    render :layout => false
  end
  
  def merging_patients
    primary_patient = Patient.find(params[:par_pat]) rescue nil
    secondary_patient = Patient.find(params[:sec_pat]) rescue nil
    if primary_patient and secondary_patient and not (primary_patient == secondary_patient)
      Patient.merge(primary_patient.id,secondary_patient.id)
      secondary_patient.reset_outcomes
      secondary_patient.reset_adherence_rates
      flash[:notice] = 'Successfully merged patients'
      redirect_to :action => "merge_show" ; return
    else
      flash[:error] = "Error - Could not merge patients"
      redirect_to :action => "merge_show" ; return
    end
  end

  def retrospective_data_entry
    if session[:patient_program] == "TB"
      redirect_to :action => "tb_card" ,:id => params[:id] ; return
    end  

    if params[:edit_visit] == "true"
      @edit_visit_date = params[:date]
      unless params[:redo] == "true"
        redirect_to :action => "encounters",:id => params[:id] ,:date => params[:date]; return
      end
    end  

    patient_obj = Patient.find(params[:id])
    @patient_id = patient_obj.id
    @data = MastercardVisit.demographics(patient_obj)
    @show_previous_visits = false
    params[:visit_added] = "true" if params[:show_previous_visits] == "true"
    if params[:visit_added] == "true" 
      @previous_visits = MastercardVisit.visits(patient_obj)
      @show_previous_visits = true
    end
    @tb_status = []
    tb_concepts = Concept.find(:all,
                               :joins => "INNER JOIN concept_answer s ON s.answer_concept=concept.concept_id",
                               :conditions =>["s.concept_id=509"])
    tb_concepts.each{|status|
      @tb_status << [status.short_name,status.id]
    }
   
    last_dispensed_date =  patient_obj.encounters.find_last_by_type_name("Give drugs").encounter_datetime.to_date rescue nil 
    drug_orders = patient_obj.drug_orders_for_date(last_dispensed_date) unless last_dispensed_date.blank?
    #drugs = Drug.find(:all).map{|d|[d.short_name,d.id] if d.arv?}.compact rescue nil 
    @drugs = []
    drug_orders.each{|order|
      drug = order.drug
      @drugs << [drug.short_name,drug.id]
    } rescue []


    @drugs = @drugs.uniq rescue []
    @outcomes = ["Alive","Died","TO(with note)","TO(without note)","Stop"] 
    @gave = ['Patient','Guardian']
    @s_effets = ['Abdominal pain','Anorexia','Diarrhoea','Anaemia','Lactic acidosis','Peripheral neuropathy','Hepatitis'] 
    @period = ["2 Weeks","1 Month","2 Months","3 Months","4 Months","5 Months","6 Months"]

    @regimen = Array.new
    regimen_types = ['ARV First line regimen', 'ARV First line regimen alternatives', 'ARV Second line regimen']
      regimen_types.collect{|regimen_type|
        Concept.find_by_name(regimen_type).concepts.flatten.compact.collect{|set|
          set.concepts.flatten.compact.collect{|concept|
            next if concept.name.include?("Triomune Baby") and !patient_obj.child?
            next if concept.name.include?("Triomune Junior") and !patient_obj.child?
            concept_name = concept.name ; concept_id = concept.id
            if concept_name.include?("Baby")
              @regimen << ["#{concept.short_name} (Baby)", concept_id]
            elsif concept_name.include?("(fixed)")
              @regimen << ["#{concept.short_name} (fixed)", concept_id]
            else
              @regimen << [concept.short_name, concept_id]
            end
          }
        }
    }
    @regimen.uniq rescue []

    @locations = Location.find(:all).collect{|l|l.name if l.id < 1000}.compact
    @back_to_main_menu = true
    @back_to_main_menu = false if params[:visit_added].blank?

    @show_height = true
    if !patient_obj.child? and patient_obj.current_height
      @show_height = false
    end  

    locations = Location.find(:all,:conditions =>["location_id < 1000"]).collect{|l|l.name}.compact
    @locations = ["",""]
    @locations[1] = Location.current_location.name
    if @locations[1] == "Zomba Central Hospital"
      ["Matawale Urban Health Centre","Domasi Rural Hospital","Zomba Prison Dispensary",
      "Zomba Central Hospital(HCW)","Likangala Health Centre","Chipini Health Centre","Bimbi Health Centre",
      "Nkasala Health Centre","Matiya Health Centre","Pirimiti Health Centre","Mayaka Health Centre","Thondwe Dispensary",
      "Chilipa Health Centre (Zomba)","Lambulira Health Centre","Magomero Health Centre","Namasalima Health Centre (Zomba)",
      "H Parker Sharp Dispensary","Chamba Dispensary (Zomba)"].sort.collect{|l|@locations << l}
    end

    locations.map{|l|
      next if @locations.include?(l)
      @locations << l
    }

    moble_site = Encounter.find(:last,:conditions =>["patient_id = ? AND encounter_type IN (?)",
        patient_obj.id,[1,2,3,5,6,7,14]],:order => "encounter_datetime ASC").location.name rescue nil

    moble_site = nil if moble_site == @locations[1]
    @patient_current_site = moble_site
    encounter_type = EncounterType.find_by_name("Decentralize patient").id

    site_id = Observation.find(:first,
        :joins => "INNER JOIN encounter e ON e.encounter_id=obs.encounter_id",
        :conditions => ["obs.patient_id = ? AND obs.voided = 0 AND encounter_type = ?",
        patient_obj.id,encounter_type],
        :order => "obs_datetime DESC,obs.date_created DESC").value_numeric rescue nil
        
    dc_site = Location.find(site_id).name unless site_id.blank?
    @patient_current_site = dc_site unless dc_site.blank?
    @patient_current_site_head = "Mobile site:" unless moble_site.blank?
    @patient_current_site_head = "DC site:" unless dc_site.blank?

    render(:layout => "layouts/mastercard")
  end

  def add
    @stage = staging_question
    locations = Location.find(:all,:conditions =>["location_id < 1000"]).collect{|l|l.name}.compact
    @locations = ["",""]
    @locations[1] = Location.current_location.name
    if @locations[1] == "Zomba Central Hospital"
      ["Matawale Urban Health Centre","Domasi Rural Hospital","Zomba Prison Dispensary",
      "Zomba Central Hospital(HCW)","Likangala Health Centre","Chipini Health Centre","Bimbi Health Centre",
      "Nkasala Health Centre","Matiya Health Centre","Pirimiti Health Centre","Mayaka Health Centre","Thondwe Dispensary",
      "Chilipa Health Centre (Zomba)","Lambulira Health Centre","Magomero Health Centre","Namasalima Health Centre (Zomba)",
      "H Parker Sharp Dispensary","Chamba Dispensary (Zomba)"].sort.collect{|l|@locations << l}
    end

    locations.map{|l|
      next if @locations.include?(l)
      @locations << l
    }
   
    unless @locations[1] == "Zomba Central Hospital"
      @occupation = [" ", "Housewife", "Farmer", "Police", "Soldier", "Business","Teacher", "Student","Healthcare Worker"].sort.concat(["Other"])
    else
      @occupation = [" ", "Housewife", "Farmer", "Police", "Soldier",
      "Prisoner","Business","Teacher", "Student","Healthcare Worker"].sort.concat(["Other"])
    end    
    render(:layout => "layouts/mastercard")
  end

  def staging_question
    if params[:age].blank?
      birthdate = params[:birthdate].to_date rescue Date.today
      curr_date = Date.today
      patient_age = (curr_date.year - birthdate.year) + ((curr_date.month - birthdate.month) + ((curr_date.day - birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)
      adult_or_peds = "adult"
      adult_or_peds = "peds" if patient_age <= 14  
    else
      adult_or_peds = "adult"
      adult_or_peds = "peds" if params[:age].to_i <= 14  
      params[:birthdate] = Date.today
    end
    @stage = {}
    for stage_number in [1,2,3,4]  
      concept_names_and_ids = Concept.find_by_name("WHO Stage #{stage_number} #{adult_or_peds}").concept_sets_controlled.collect{|cs|
        next if cs.concept.retired?
        [cs.concept.name,cs.concept.id]
      }.compact
      @stage["stage#{stage_number}"] =  concept_names_and_ids
    end 
    return @stage if params[:birthdate].blank?
    render :text => @stage.to_json ; return
  end

  def save
    visit_year =  params[:visit_date]["(1i)"].to_i rescue nil
    visit_month =  params[:visit_date]["(2i)"].to_i rescue nil
    visit_day =  params[:visit_date]["(3i)"].to_i rescue nil
		session[:encounter_datetime] = Time.mktime(visit_year,visit_month,visit_day,0,0,1)
    date_of_positive_hiv_test = Concept.find_by_name("Date of positive HIV test").id
    date_of_art_initiation = Concept.find_by_name("Date of ART initiation").id
    location_of_first_positive_hiv_test = Concept.find_by_name("Location of first positive HIV test").id
    location_of_art_initiation = Concept.find_by_name("Location of ART initiation").id
    ever_registered_at_art_clinic = Concept.find_by_name("Ever registered at ART clinic").id
    ever_received_art = Concept.find_by_name("Ever received ART").id
    taken_art_in_last_2_weeks = Concept.find_by_name("Taken ART in last 2 weeks").id
    first_positive_hiv_test = Concept.find_by_name("First positive HIV Test").id
    has_transfer_letter = Concept.find_by_name("Has transfer letter").id
    agrees_to_followup = Concept.find_by_name("Agrees to followup").id
    arv_number_at_that_site = Concept.find_by_name("ARV number at that site").id
    site_transferred_from = Concept.find_by_name("Site transferred from").id
    weight = Concept.find_by_name("Weight").id
    height = Concept.find_by_name("Height").id
    yes = Concept.find_by_name("Yes").id
    no = Concept.find_by_name("No").id

    cd4_count = Concept.find_by_name("CD4 count").id
    cd4_percentage = Concept.find_by_name("CD4 percentage").id
    cd4_count_available = Concept.find_by_name("CD4 count available").id
    cd4_test_date = Concept.find_by_name("CD4 test date").id

    cd4 = params[:cd4_count].to_s rescue nil 
    cd4_mod = params[:mod_cont]
    mod_perc = params[:mod_perc]
    cd4_per = params[:cd4_per].to_s rescue nil

    cd4_available = no
    cd4_available = yes unless cd4.blank?
    cd4_percentage_available = no
    cd4_percentage_available = yes unless cd4_per.blank?

    first_name = params[:name].to_s.strip.squeeze(" ").split(" ")[0].capitalize rescue ""
    last_name = params[:name].to_s.strip.squeeze(" ").split(" ")[1].capitalize rescue ""
    occupation = params[:occupation]
    patientaddress = params[:address]
    birth_year =  params[:birthdate]["(1i)"].to_i rescue nil
    birth_month =  params[:birthdate]["(2i)"].to_i rescue nil
    birth_day =  params[:birthdate]["(3i)"].to_i rescue nil
    land_mark = params[:landmark]
    birth_place = params[:birthplace].to_s
    ta = params[:ta]
    gender = params[:sex]
    birthdate_est = params[:estimated]

    guardian_name =  params[:guardian_name].to_s.split(' ')[0] rescue ''
    guardian_family_name =  params[:guardian_name].to_s.split(' ')[1] rescue ''

    if session[:patient_program] == "HIV"
      #1st HIV visit
      ever_reg = "" ; be_visited = "" ; ever_received = ""
      ever_received = no if params[:ever_received] == "No"
      ever_received = yes if params[:ever_received] == "Yes"
      agrees_to_be_visited = no if params[:be_visited] == "No"
      agrees_to_be_visited = yes if params[:be_visited] == "Yes"
      ever_reg = no if params[:ever_reg] == "No"
      ever_reg = yes if params[:ever_reg] == "Yes"
      location_of_1st_test = params[:loc_1st_test]
      pos_test_date_year = params[:positive_test_date]["test_date(1i)"]
      pos_test_date_month = params[:positive_test_date]["test_date(2i)"]
      pos_test_date_day = params[:positive_test_date]["test_date(3i)"]

      hiv_test = ""
      unless params[:first_positive_hiv_test].blank?
        hiv_test = Concept.find_by_name("First positive HIV Test").id
      end
      
      parameters = {}

      preg_whn_starting = '' ; ever_taken_in_last_wk = '' ; has_trans_lt = ''
      initiation_location = '' ; site_trans_frm = '' ; initiation_weight = ''
      initiation_height = '' ; initiation_year = '' ; initiation_month = ''
      initiation_day = '' ; arv_number_at_site = ''
      if ever_reg == yes || ever_received == yes 
        if gender == "Female"
          preg_whn_starting = no if params[:preg_whn_starting] == "No"
          preg_whn_starting = yes if params[:preg_whn_starting] == "Yes"
        end  
        ever_taken_in_last_wk = no if params[:ever_taken_in_last_wk] == "No"
        ever_taken_in_last_wk = yes if params[:ever_taken_in_last_wk] == "Yes"
        initiation_location = params[:init_loc]
        site_trans_frm = params[:site_trans_frm]
        has_trans_lt = no  if params[:has_trans_lt] == "No"
        has_trans_lt = yes  if params[:has_trans_lt] == "Yes"
        initiation_year =  params[:init_date]["init_date(1i)"]
        initiation_month = params[:init_date]["init_date(2i)"]
        initiation_day = params[:init_date]["init_date(3i)"]
        arv_number_at_site = params[:arv_number_at_site_]
      end
      initiation_weight = params[:weightWS].to_s rescue ''
      initiation_height = params[:heightWS].to_s rescue ''
    end

    age_estimate = ""
    if birthdate_est == "True"
      birth_year = (session[:encounter_datetime].year - params[:estimated_age].to_s.to_i)
      birth_month = 0
      birth_day = 0
      today = Date.today
      age_estimate = (today.year - birth_year) + ((today.month - birth_month) + ((today.day - birth_day) < 0 ? -1 : 0) < 0 ? -1 : 0)
      birth_year = "Unknown"
    end

    if session[:patient_program] == "HIV"
 parameters["art_visit"] = {:form_id =>"54","#{date_of_art_initiation}_day"=>initiation_day,
 :observation => {"location:#{location_of_first_positive_hiv_test}"=>location_of_1st_test,
 "location:#{location_of_art_initiation}"=>initiation_location,
 "number:#{weight}"=>initiation_weight,
 "select:#{ever_registered_at_art_clinic}"=>ever_reg,
 "select:#{ever_received_art}"=>ever_received,
 "select:#{taken_art_in_last_2_weeks}"=>ever_taken_in_last_wk,
 "select:#{first_positive_hiv_test}"=>hiv_test,
 "select:#{has_transfer_letter}"=>has_trans_lt,
 "select:#{agrees_to_followup}"=>agrees_to_be_visited,
 "number:#{arv_number_at_that_site}"=>arv_number_at_site,
 "number:#{height}"=>initiation_height,
 "location:#{site_transferred_from}"=>site_trans_frm},
 :encounter_type_id => "#{EncounterType.find_by_name('HIV First visit').id}",
 "#{date_of_art_initiation}_year"=>initiation_year,
 "#{date_of_positive_hiv_test}_day"=>pos_test_date_day,
 "#{date_of_positive_hiv_test}_month"=>pos_test_date_month,
 "#{date_of_positive_hiv_test}_year"=>pos_test_date_year,
 "#{date_of_art_initiation}_month"=>initiation_month}

  cd4_mode_plus_cd4_count = "#{cd4_mod}#{cd4}" unless cd4.blank?
  cd4_mode_plus_cd4_perc = "#{mod_perc}#{cd4_per}" unless cd4_per.blank?
  parameters["hiv_staging"] = {:form_id =>"56",:stage3 => params[:stage_three],:stage4 => params[:stage_four],
  :stage2 => params[:stage_two],:stage1 => params[:stage_one],
  :observation =>{"number:#{cd4_count}"=>"#{cd4_mode_plus_cd4_count}","select:#{cd4_count_available}"=>cd4_available,
 "number:#{cd4_percentage}"=>"#{cd4_mode_plus_cd4_perc}"},
  :encounter_type_id =>"#{EncounterType.find_by_name('HIV Staging').id}",
 "#{cd4_test_date}_day"=>"12","#{cd4_test_date}_year"=>"2009","#{cd4_test_date}_month"=>"3"} 

  
    parameters["hiv_staging"].delete(:stage1) if  parameters["hiv_staging"][:stage1].blank?
    parameters["hiv_staging"].delete(:stage2) if  parameters["hiv_staging"][:stage2].blank?
    parameters["hiv_staging"].delete(:stage3) if  parameters["hiv_staging"][:stage3].blank?
    parameters["hiv_staging"].delete(:stage4) if  parameters["hiv_staging"][:stage4].blank?

    create_hiv_staging_encounter = "false"
    create_hiv_staging_encounter = "true" unless  parameters["hiv_staging"][:stage1].blank?
    create_hiv_staging_encounter = "true" unless  parameters["hiv_staging"][:stage2].blank?
    create_hiv_staging_encounter = "true" unless  parameters["hiv_staging"][:stage3].blank?
    create_hiv_staging_encounter = "true" unless  parameters["hiv_staging"][:stage4].blank?
    create_hiv_staging_encounter = "true" unless  cd4.blank?
    create_hiv_staging_encounter = "true" unless  cd4_per.blank?
  end


  create_guardian = "false"
  create_guardian = "true" unless guardian_name.blank?
  
  unless params[:home_phone].blank?
    home_phone = params[:home_phone].to_s
  else
    home_phone = "Not Available"
  end
  
  create_hiv_first_visit = "false"
  if session[:patient_program] == "HIV"
    create_hiv_first_visit = "true" unless ever_reg.blank? 
  end
    
# variables needed to create patient
  if session[:patient_program] == "HIV"
      redirect_to :action => "create",:occupation =>occupation,:patient_year =>birth_year,:patient =>{"gender"=>gender,"birthplace"=>birth_place},"p_address"=>{"identifier"=>land_mark},:home_phone =>{"identifier"=> home_phone},:patient_id=>"","patient_day"=>birth_day,:patientaddress =>{"city_village"=>patientaddress},:patient_name =>{"family_name"=>last_name,"given_name"=>first_name}, :patient_month =>birth_month,:patient_age =>{"age_estimate"=>age_estimate},"age"=>{"identifier"=>""},:current_ta =>{"identifier"=>ta},
# variables needed to create guardian
    :guardian_name => guardian_name,:create_from_mastercard => "true",
    :guardian_family_name => guardian_family_name,:guardian_gender => params[:guardian_sex], 
    :relationship_type => params[:relationship],
# variables needed to create patient 1st visit
   :art_visit => parameters["art_visit"],
# variables needed to create patient hiv staging
    :hiv_staging => parameters["hiv_staging"],:create_first_visit => create_hiv_first_visit,
    :create_staging => create_hiv_staging_encounter,
    :create_guardian => create_guardian,:location_name => params[:location_name],
    :guardian_phone_number => params[:guardian_phone_number].to_s ; return
  else
      redirect_to :action => "create",:occupation =>occupation,:patient_year =>birth_year,:patient =>{"gender"=>gender,"birthplace"=>birth_place},"p_address"=>{"identifier"=>land_mark},:home_phone =>{"identifier"=> home_phone},:patient_id=>"","patient_day"=>birth_day,:patientaddress =>{"city_village"=>patientaddress},:patient_name =>{"family_name"=>last_name,"given_name"=>first_name}, :patient_month =>birth_month,:patient_age =>{"age_estimate"=>age_estimate},"age"=>{"identifier"=>""},:current_ta =>{"identifier"=>ta},
  :location_name => params[:location_name],:guardian_phone_number => params[:guardian_phone_number].to_s ; return
  end

  end

  def retrospective_data_entry_menu
    session[:patient_program] = params[:program] unless params[:program].blank?
    if session[:patient_program].blank?
      redirect_to :action => "program" ; return
    end
    render(:layout => false)
  end
  
  def quick_search

    redirect_to :action => "program" if session[:patient_program].blank?
   
    unless params[:search_str].blank?
      first_name_chr = params[:search_str].first rescue ""
      last_name = params[:search_str].split(" ")[1] || params[:search_str]
      @patients = Patient.find(:all,
         :joins => "INNER JOIN patient_name pn ON patient.patient_id=pn.patient_id",
         :conditions => ["given_name LIKE ? AND family_name LIKE ? AND gender = ? AND pn.voided=0",
         "#{first_name_chr}%", "%#{last_name}%",params[:gender]],:group => "patient.patient_id")

      if @patients.blank?
        @patients_not_found = true
        render :partial => 'quick_search' and return  
      end

    @html = <<EOF
<html>
<head>
<style>
  .color_blue{
    border-style:solid;
  }
  .color_white{
    border-style:solid;
  }

  th{
    border-style:solid;
  }
</style>
</head>
<body>
<br/>
<table id="data_table">
  <thead>
    <tr>
      <th class='tb_art'>ARV number</th>
      <th class='tb'>TB number</th>
      <th>Name</th>
      <th>Birthdate</th>
      <th>Guardian</th>
      <th>Address</th>
      <th>National ID</th>
      <th class='tb_art'>ART Start date</th>
      <th>TA</th>
    </tr>
  </thead>
  <tbody>
EOF

      color = 'blue'
      @patients.each do |patient|
        if color == 'blue'
          color = 'white'
        else
          color='blue'
        end
        @html+= <<EOF
<tr>
  <td class='color_#{color} tb' style="text-align:left;" onclick='setPatient(#{patient.id})'>#{patient.tb_number || '&nbsp;'}</td>
  <td class='color_#{color} tb_art' style="text-align:left;" onclick='setPatient(#{patient.id})'>#{patient.arv_number || '&nbsp;'}</td>
  <td class='color_#{color}' style="text-align:left;" onclick='setPatient(#{patient.id})'>#{patient.name rescue '&nbsp;'}</td>
  <td class='color_#{color}' style="text-align:left;" onclick='setPatient(#{patient.id})'>#{patient.birthdate_for_printing rescue '&nbsp;'}</td>
  <td class='color_#{color}' style="text-align:left;" onclick='setPatient(#{patient.id})'>#{patient.art_guardian.name rescue '&nbsp;'}</td>
  <td class='color_#{color}' style="text-align:left;" onclick='setPatient(#{patient.id})'>#{patient.physical_address || '&nbsp;'}</td>
  <td class='color_#{color}' style="text-align:left;" onclick='setPatient(#{patient.id})'>#{patient.print_national_id || '&nbsp;'}</td>
  <td class='color_#{color} tb_art' style="text-align:left;" onclick='setPatient(#{patient.id})'>#{patient.date_started_art.strftime('%Y-%m-%d') rescue '&nbsp;'}</td>
  <td class='color_#{color}' style="text-align:left;" onclick='setPatient(#{patient.id})'>#{patient.traditional_authority || '&nbsp;'}</td>
</tr>
EOF
      end
      
      @html+="</tbody></table></body></html>"   
        
      render :partial => 'quick_search' ; return  
    end  
    render(:layout => false)
  end

  def create_remote
    #estimate = set_date() # check for estimated birthdates and alter params if necessary
    estimate = set_date()     
    
    patient_birthdate = params['patient_day'].to_s + "-" + params['patient_month'].to_s + "-" + params['patient_year'].to_s 
    #put validation to check if patient has id then @patient should be initialised to this
    @patient = Patient.new(params[:patient]) 
    @patient.save
    #render_text @patient.to_yaml and return
    @patientname = PatientName.new(params[:patient_name])
    @patientname.patient = @patient
    @patientname.save           
    @patient.birthdate = patient_birthdate.to_date.to_s 
    @patient.birthdate_estimated = estimate  
   
    PatientAddress.create(@patient.id,params[:patientaddress])
    PatientIdentifier.create(@patient.id, params[:current_ta], "Traditional authority")
    PatientIdentifier.create(@patient.id, params[:other_name], "Other name")
    PatientIdentifier.create(@patient.id, params[:home_phone], "Home phone number")
    PatientIdentifier.create(@patient.id, params[:cell_phone], "Cell phone number")
    PatientIdentifier.create(@patient.id, params[:office_phone], "Office phone number")
    PatientIdentifier.create(@patient.id, params[:occupation], "Occupation")
    PatientIdentifier.create(@patient.id, params[:p_address], "Physical address")
    @patient.set_national_id # setting new national id
     
    national_id = @patient.national_id
    params_to_pass = {"person" => {"patient" => {"identifiers" => {"National id" => "#{national_id}"}}}}
    if @patient.save
     people = Patient.find_by_demographics(params_to_pass)
    end
    #result = people.empty? ? {} : people
    render :text => people.to_json
  end
 
  def program
    render(:layout => false)
  end

  def void_tb_record
    encounter = Encounter.find(params[:encounter_id])
    encounter.void!("Error")
    @patient_id = params[:id]
    @previous_visits = MastercardVisit.tb_visits(params[:id])
    render :partial => "mastercard_tb_visits" and return
  end

  def tb_card
    session[:patient_id] = nil
    patient = Patient.find(params[:id])
    @patient_id = patient.id
    @data = MastercardVisit.demographics(patient)
    @show_previous_visits = false
    params[:visit_added] = "true" if params[:show_previous_visits] == "true"

     

    tb_encounter_type = EncounterType.find_by_name("TB Visit").id
    concept = Concept.find_by_name("Extrapulmonary tuberculosis")
   
    tb_type = Observation.find(:first,
        :joins => "INNER JOIN encounter e ON e.encounter_id = obs.encounter_id",
        :conditions =>["voided=0 AND e.encounter_type=? AND e.patient_id=? AND concept_id=?",
        tb_encounter_type,patient.id,concept.id])
   
    @pre_tb_type = "Extrapulmonary tuberculosis" unless tb_type.blank?
    if @pre_tb_type.blank?
      concept = Concept.find_by_name("Pulmonary tuberculosis (current)")
      tb_type = Observation.find(:first,
          :joins => "INNER JOIN encounter e ON e.encounter_id = obs.encounter_id",
          :conditions =>["voided=0 AND e.encounter_type=? AND e.patient_id=? AND concept_id=?",
          tb_encounter_type,patient.id,concept.id])
      @pre_tb_type = "Pulmonary tuberculosis (current)" unless tb_type.blank?
    end

    @pre_tb_regimen = patient.observations.find_last_by_concept_name("TB Regimen").to_s.gsub("TB Regimen:","").strip rescue nil
    @pre_tb_episode = patient.observations.find_last_by_concept_name("TB Episode type").to_s.gsub("TB Episode type:","").strip rescue nil
    @pre_prescribe_cpt = patient.observations.find_last_by_concept_name("Cotrimoxazole").to_s.gsub("Cotrimoxazole:","").strip rescue nil
    @pre_tb_start_treatment_date = patient.observations.find_last_by_concept_name("TB start treatment date").to_s.gsub("TB start treatment date:","").strip.to_date.to_s rescue nil

    identifier_type = PatientIdentifierType.find_by_name("TB treatment ID").id
    @tb_id = PatientIdentifier.find(:first,
        :conditions => ["voided = 0 AND patient_id =? AND identifier_type = ?",patient.id,identifier_type]).identifier rescue nil


   @previous_visits = MastercardVisit.tb_visits(patient.id)
   session[:patient_id] = nil
   render(:layout => "layouts/mastercard")
  end
  
  def tb_entry_card
    patient = Patient.find(params[:id]) 
    art_status_concept_id = Concept.find_by_name("ART status").id
    tb_episode_type_concept_id = Concept.find_by_name("TB Episode type").id
    tb_regimen_concept_id = Concept.find_by_name("TB Regimen").id
    prescribe_tb_concept_id = Concept.find_by_name("Cotrimoxazole").id
    
    tb_encounter_type = EncounterType.find_by_name("TB Visit").id
    concept = Concept.find_by_name("Extrapulmonary tuberculosis")

    tb_type = Observation.find(:first,
        :joins => "INNER JOIN encounter e ON e.encounter_id = obs.encounter_id",
        :conditions =>["voided=0 AND e.encounter_type=? AND e.patient_id=? AND concept_id=?",
        tb_encounter_type,patient.id,concept.id])

    @pre_tb_type = "Extrapulmonary tuberculosis" unless tb_type.blank?
    if @pre_tb_type.blank?
      concept = Concept.find_by_name("Pulmonary tuberculosis (current)")
      tb_type = Observation.find(:first,
          :joins => "INNER JOIN encounter e ON e.encounter_id = obs.encounter_id",
          :conditions =>["voided=0 AND e.encounter_type=? AND e.patient_id=? AND concept_id=?",
          tb_encounter_type,patient.id,concept.id])
      @pre_tb_type = "Pulmonary tuberculosis (current)" unless tb_type.blank?
    end

    @pre_tb_regimen = patient.observations.find_last_by_concept_name("TB Regimen").to_s.gsub("TB Regimen:","").strip rescue nil
    @pre_tb_episode = patient.observations.find_last_by_concept_name("TB Episode type").to_s.gsub("TB Episode type:","").strip rescue nil
    @pre_prescribe_cpt = patient.observations.find_last_by_concept_name("Cotrimoxazole").to_s.gsub("Cotrimoxazole:","").strip rescue nil

    flash[:error] = nil
    @tb_type = [""]
    Concept.find(:all,:conditions => ["name LIKE ?","%Pulmonary tuberculosis%"]).map{|c|@tb_type << c.name} rescue []
    @espisode_type = ["","New","Relapse","Retreat","Failed"]
    @tb_regimen = ["","Regimen 1","Regimen 2","TB Meningitis"]
    @tb_outcome = ["","Died","Defaulter","Stop","Transfer out","Failed","Cured","On TB Treatment","Completed"]
    @sputum_count = ["","-","+","++","+++","Unknown"]
    @art_status = ["","A","B","C","Unknown"]

    identifier_type = PatientIdentifierType.find_by_name("TB treatment ID").id 
    @tb_id = PatientIdentifier.find(:first,
        :conditions => ["voided = 0 AND patient_id =? AND identifier_type = ?",patient.id,identifier_type]).identifier rescue nil

    concept_id = Concept.find_by_name("TB start treatment date").id 
    @tb_start_treatment_date = Observation.find(:first,
        :conditions => ["voided = 0 AND patient_id =? AND concept_id = ?",patient.id,concept_id]).value_datetime rescue nil

    @patient_name = patient.name ; @arv_number = patient.arv_number 
    @patient_id = patient.id ; @national_id = patient.national_id

    current_numbers = []
    PatientIdentifier.find(:all,
    :conditions=>['identifier_type=? and voided=0',PatientIdentifierType.find_by_name("TB treatment ID").id],
    :group => 'identifier').collect{|d|
      next if d.identifier.match(/[0-9]+/).blank?
      current_numbers << d.identifier #.match(/[0-9]+/)[0].to_i 
    } rescue nil
    @current_numbers = current_numbers.sort.to_json rescue []

    render(:layout => false)
    #layouts/mastercard
  end

  def create_tb_encounter
    visit_date = "#{params[:visit_date]['(1i)']}-#{params[:visit_date]['(2i)']}-#{params[:visit_date]['(3i)']}".to_date rescue nil
    end_date = "#{params[:end_year]['(1i)']}-#{params[:end_year]['(2i)']}-#{params[:end_year]['(3i)']}".to_date rescue nil
    start_date = "#{params[:start_year]['(1i)']}-#{params[:start_year]['(2i)']}-#{params[:start_year]['(3i)']}".to_date rescue nil

    selected_regimen = params[:regimen]
    tb_id = params[:tb_id]
    cpt = params[:cpt]
    sputum_count = 0 if params[:sputum] == '-' ; sputum_count = 1 if params[:sputum] == '+'
    sputum_count = 2 if params[:sputum] == '++' ; sputum_count = 3 if params[:sputum] == '+++'
    episode_type = params[:episode_type]
    art_status = params[:art_status]

    patient = Patient.find(params[:patient_id]) rescue nil
    if patient.blank? 
      flash[:error] = "Patient not found"
      redirect_to :action => "tb_entry_card" ,:id => params[:patient_id]; return
    end

    start_treatment_date = Concept.find_by_name("TB start treatment date").id
    end_treatment_date = Concept.find_by_name("TB end treatment date").id
    #yes = Concept.find_by_name("Yes").id
    #no = Concept.find_by_name("No").id

    encounter = Encounter.new
    encounter.patient_id = patient.id
    encounter.type = EncounterType.find_by_name("TB Reception")
    encounter.encounter_datetime = visit_date
    encounter.provider_id = User.current_user.id
    encounter.save    

    obs = Observation.new
    obs.encounter = encounter
    obs.patient_id = patient.id
    obs.concept_id = Concept.find_by_name("Patient present").id
    obs.value_coded = Concept.find_by_name("Yes").id
    obs.obs_datetime = encounter.encounter_datetime
    obs.save

    encounter = Encounter.new
    encounter.patient_id = patient.id
    encounter.type = EncounterType.find_by_name("TB Visit")
    encounter.encounter_datetime = visit_date
    encounter.provider_id = User.current_user.id
    encounter.save    

    if tb_id
      identifier = PatientIdentifier.new
      identifier.identifier_type = PatientIdentifierType.find_by_name("TB treatment ID").id
      identifier.patient_id = patient.id
      identifier.identifier = tb_id.to_s
      identifier.save
    end rescue nil

    if params[:tb_type]
      obs = Observation.new
      obs.encounter = encounter
      obs.patient_id = patient.id
      obs.value_coded = Concept.find_by_name("Yes").id
      obs.concept_id = Concept.find_by_name(params[:tb_type]).id
      obs.obs_datetime = encounter.encounter_datetime
      obs.save
    end


    unless start_date.blank?
      obs = Observation.new
      obs.encounter = encounter
      obs.patient_id = patient.id
      obs.concept_id = Concept.find_by_name("TB start treatment date").id
      obs.value_datetime = start_date
      obs.obs_datetime = encounter.encounter_datetime
      obs.save
    end

    if params[:regimen]
      obs = Observation.new
      obs.encounter = encounter
      obs.patient_id = patient.id
      obs.concept_id = Concept.find_by_name("TB Regimen").id
      obs.value_coded = Concept.find_by_name(params[:regimen]).id
      obs.obs_datetime = encounter.encounter_datetime
      obs.save
    end

    if params[:cpt]
      obs = Observation.new
      obs.encounter = encounter
      obs.patient_id = patient.id
      obs.concept_id = Concept.find_by_name("Cotrimoxazole").id
      obs.value_coded = Concept.find_by_name(params[:cpt]).id
      obs.obs_datetime = encounter.encounter_datetime
      obs.save
    end

    if params[:episode_type]
      obs = Observation.new
      obs.encounter = encounter
      obs.patient_id = patient.id
      obs.concept_id = Concept.find_by_name("TB Episode type").id
      obs.value_coded = Concept.find_by_name(params[:episode_type]).id
      obs.obs_datetime = encounter.encounter_datetime
      obs.save
    end

    # The following obs may change over time but usually don't
    obs = Observation.new
    obs.encounter = encounter
    obs.patient_id = patient.id
    obs.concept_id = Concept.find_by_name("ART status").id
    obs.value_coded = Concept.find_by_name(params[:art_status]).id
    obs.obs_datetime = encounter.encounter_datetime
    obs.save

    obs = Observation.new
    obs.encounter = encounter
    obs.patient_id = patient.id
    obs.concept_id = Concept.find_by_name("TB sputum count").id
    obs.value_numeric = sputum_count
    obs.obs_datetime = encounter.encounter_datetime
    obs.save

    obs = Observation.new
    obs.encounter = encounter
    obs.patient_id = patient.id
    obs.concept_id = Concept.find_by_name("Outcome").id
    obs.value_coded = Concept.find_by_name(params[:outcome]).id
    obs.obs_datetime = encounter.encounter_datetime
    obs.save

    unless end_date.blank?
      obs = Observation.new
      obs.encounter = encounter
      obs.patient_id = patient.id
      obs.concept_id = Concept.find_by_name("TB end treatment date").id
      obs.value_datetime = end_date
      obs.obs_datetime = encounter.encounter_datetime
      obs.save
    end

    patient.add_programs([Program.find_by_concept_id(Concept.find_by_name("Tuberculosis (TB)").id)]) unless patient.tb_patient?
    redirect_to :action => "tb_card", :id => params[:patient_id] ; return
  end

  def edit_visit
    redirect_to :action => "retrospective_data_entry",:id => params[:id],
      :date => params[:date],:edit_visit => "true"
    return
  end

  def latest_drugs_given_before
    @drugs = []
    date = params[:date].to_date rescue nil
    encounter_type = EncounterType.find_by_name("Give drugs").id
    encounter_id = Encounter.find(:first,
                    :joins => "INNER JOIN orders ON orders.encounter_id = encounter.encounter_id",
                    :conditions => ["patient_id = ? AND encounter_type =? AND voided=0 AND encounter_datetime < ?",
                    params[:id],encounter_type,date],:order => "encounter_datetime DESC").encounter_id rescue nil

    orders = Order.find(:all,:conditions =>["encounter_id = ?",encounter_id]) rescue nil
    order_ids = orders.map{|o|o.order_id} rescue []
    drug_orders = DrugOrder.find(:all,:conditions => ["order_id IN (?)",order_ids])
    drug_orders.each{|order|
      drug = order.drug
      @drugs << [drug.short_name,drug.id]
    } rescue nil
    @drugs = @drugs.uniq rescue []
    render :partial => "remaining_pills" and return
  end

  def create_and_set_guardian
    person = Patient.new()
    person.gender = params[:sex]
    person.save
    person.set_national_id
    guardian_name = PatientName.new()
    guardian_name.patient_id = person.id
    guardian_name.given_name = params[:first]
    guardian_name.family_name = params[:last]
    guardian_name.save
    Patient.find(params[:id]).set_art_guardian_relationship(person,params[:relationship_type])
    if session[:patient_program] == "HIV"
      redirect_to :action => "retrospective_data_entry",:id => params[:id], :visit_added => "true"
    else
      redirect_to :action => "tb_card",:id => params[:id],:visit_added => "true"
    end    
    return
  end
  
  def compare_date
    date = params[:date].to_date
    render :text => "false" and return if date > Date.today
    render :text => "true" ; return
  end

  def staging
    if request.method == :get    
      locations = Location.find(:all,:conditions =>["location_id < 1000"]).collect{|l|l.name}.compact
      @locations = ["",""]
      @locations[1] = Location.current_location.name
      if @locations[1] == "Zomba Central Hospital"
        ["Matawale Urban Health Centre","Domasi Rural Hospital","Zomba Prison Dispensary",
        "Zomba Central Hospital(HCW)","Likangala Health Centre"].collect{|l|@locations << l}
      end

      locations.map{|l|
        next if @locations.include?(l)
        @locations << l
      }
      @stage = staging_question
      @patient_id = params[:id] ; @encounter_date = params[:date] || Date.today
      @change_staging_col = true
      @show_locations = true
      render :layout => false
    else
      Location.set_current_location = Location.find_by_name(params[:location_name])
      encounter_date = "#{params[:visit_date]['(1i)']}-#{params[:visit_date]['(2i)']}-#{params[:visit_date]['(3i)']}".to_date
      @patient = Patient.find(params[:id])
      encounter_type = EncounterType.find_by_name("HIV Staging").id

      encounters = Encounter.find(:all,:conditions =>["encounter_type =? AND patient_id=?",
        encounter_type,@patient.id])
      encounters.each do |encounter|
        encounter.void!("HIV Staging:redo")
      end

      encounter = Encounter.new()
      encounter.encounter_type = encounter_type
      encounter.encounter_datetime = encounter_date
      encounter.patient_id = @patient.id
      encounter.save

      yes = Concept.find_by_name("Yes").id

      params[:stage_one].each do |stage|
        Observation.create_stage(@patient.id,encounter.id,yes,stage,encounter.encounter_datetime) 
      end unless params[:stage_one].blank?

      params[:stage_two].each do |stage|
        Observation.create_stage(@patient.id,encounter.id,yes,stage,encounter.encounter_datetime) 
      end unless params[:stage_two].blank?

      params[:stage_three].each do |stage|
        Observation.create_stage(@patient.id,encounter.id,yes,stage,encounter.encounter_datetime) 
      end unless params[:stage_three].blank?

      params[:stage_four].each do |stage|
        Observation.create_stage(@patient.id,encounter.id,yes,stage,encounter.encounter_datetime) 
      end unless params[:stage_four].blank?

      unless params[:cd4_count].blank?
        obs = Observation.new
        obs.encounter_id = encounter.id
        obs.obs_datetime = encounter.encounter_datetime
        obs.patient_id = @patient.id
        obs.concept_id = Concept.find_by_name("CD4 count").id
        obs.value_numeric =  params[:cd4_count].to_s
        obs.value_modifier = params[:mod_cont]
        obs.save
      end  

      unless params[:cd4_per].blank?
        obs = Observation.new
        obs.encounter_id = encounter.id
        obs.obs_datetime = encounter.encounter_datetime
        obs.patient_id = @patient.id
        obs.concept_id = Concept.find_by_name("CD4 percentage").id
        obs.value_numeric = params[:cd4_per].to_s
        obs.value_modifier = params[:mod_perc]
        obs.save
      end  

      redirect_to :action =>"retrospective_data_entry",:id => @patient.id,
        :visit_added => true and return
    end 
  end 
  
  def first_visit
    if request.method == :get    
      @patient_id = params[:id] ; @encounter_date = params[:date] || Date.today
      @patient = Patient.find(@patient_id)
      locations = Location.find(:all,:conditions =>["location_id < 1000"]).collect{|l|l.name}.compact
      @locations = ["",""]
      @locations[1] = Location.current_location.name
      if @locations[1] == "Zomba Central Hospital"
        ["Matawale Urban Health Centre","Domasi Rural Hospital","Zomba Prison Dispensary",
        "Zomba Central Hospital(HCW)","Likangala Health Centre"].collect{|l|@locations << l}
      end

      locations.map{|l|
        next if @locations.include?(l)
        @locations << l
      }
      @show_locations = true
      render :layout => false
    else
      Location.set_current_location = Location.find_by_name(params[:location_name])
      encounter_date = "#{params[:visit_date]['(1i)']}-#{params[:visit_date]['(2i)']}-#{params[:visit_date]['(3i)']}".to_date
      hiv_test_date_year =  params[:positive_test_date]["test_date(1i)"] rescue nil
      hiv_test_date_month = params[:positive_test_date]["test_date(2i)"] rescue nil
      hiv_test_date_day = params[:positive_test_date]["test_date(3i)"] rescue nil
      hiv_test_date = "#{hiv_test_date_year}-#{hiv_test_date_month}-#{hiv_test_date_day}".to_date rescue nil

      initiation_year =  params[:init_date]["init_date(1i)"] rescue nil
      initiation_month = params[:init_date]["init_date(2i)"] rescue nil
      initiation_day = params[:init_date]["init_date(3i)"] rescue nil
      init_date = "#{initiation_year}-#{initiation_month}-#{initiation_day}".to_date rescue nil

      @patient = Patient.find(params[:id])
      encounter_type = EncounterType.find_by_name("HIV First visit").id
=begin
      encounters = Encounter.find(:all,:conditions =>["encounter_type =? AND patient_id=?",
        encounter_type,@patient.id])
      encounters.each do |encounter|
        encounter.void!("HIV First visit:redo")
      end
=end
      encounter = Encounter.new()
      encounter.encounter_type = encounter_type
      encounter.encounter_datetime = encounter_date
      encounter.patient_id = @patient.id
      encounter.save
      
      obs = Observation.new
      obs.encounter_id = encounter.id
      obs.obs_datetime = encounter.encounter_datetime
      obs.patient_id = @patient.id
      obs.concept_id = Concept.find_by_name("Date of positive HIV test").id
      unless hiv_test_date.blank?
        obs.value_datetime = hiv_test_date
      else
        obs.value_coded = Concept.find_by_name("Unknown").id
      end  
      obs.save
      
      create_obs(@patient.id,encounter.id,encounter.encounter_datetime,"Agrees to followup",params[:be_visited])
      obs = Observation.new
      obs.encounter_id = encounter.id
      obs.obs_datetime = encounter.encounter_datetime
      obs.patient_id = @patient.id
      obs.concept_id = Concept.find_by_name("Location of first positive HIV test").id
      obs.value_numeric = Location.find_by_name(params[:loc_1st_test]).id
      obs.save
      create_obs(@patient.id,encounter.id,encounter.encounter_datetime,"Ever registered at ART clinic",params[:ever_reg])
      create_obs(@patient.id,encounter.id,encounter.encounter_datetime,"Ever received ART",params[:ever_received])
      unless params[:preg_whn_starting].blank?
        create_obs(@patient.id,encounter.id,encounter.encounter_datetime,"Pregnant when art was started",params[:preg_whn_starting])
      end  

      if params[:ever_reg] == "Yes" || params[:ever_received] == "Yes"
        create_obs(@patient.id,encounter.id,encounter.encounter_datetime,"Taken ART in last 2 weeks",params[:ever_taken_in_last_wk])
        create_obs(@patient.id,encounter.id,encounter.encounter_datetime,"Has transfer letter",params[:has_trans_lt])
        obs = Observation.new
        obs.encounter_id = encounter.id
        obs.obs_datetime = encounter.encounter_datetime
        obs.patient_id = @patient.id
        obs.concept_id = Concept.find_by_name("Location of ART initiation").id
        obs.value_numeric = Location.find_by_name(params[:init_loc]).id
        obs.save

        obs = Observation.new
        obs.encounter_id = encounter.id
        obs.obs_datetime = encounter.encounter_datetime
        obs.patient_id = @patient.id
        obs.concept_id = Concept.find_by_name("Date of ART initiation").id
        unless init_date.blank?
          obs.value_datetime = init_date
        else
          obs.value_coded = Concept.find_by_name("Unknown").id
        end  
        obs.save
      end
      
      unless params[:heightWS_].blank?
        obs = Observation.new
        obs.encounter_id = encounter.id
        obs.obs_datetime = encounter.encounter_datetime
        obs.patient_id = @patient.id
        obs.concept_id = Concept.find_by_name("Height").id
        obs.value_numeric = params[:heightWS_].to_s
        obs.save
      end

      unless params[:weightWS_].blank?
        obs = Observation.new
        obs.encounter_id = encounter.id
        obs.obs_datetime = encounter.encounter_datetime
        obs.patient_id = @patient.id
        obs.concept_id = Concept.find_by_name("Weight").id
        obs.value_numeric = params[:weightWS_].to_s
        obs.save
      end

      redirect_to :action =>"encounters",:id => @patient.id,
        :date => encounter_date and return
    end
  end 
  
  def create_obs(patient_id,encounter_id,obs_date,concept_name,value_coded)
    obs = Observation.new
    obs.encounter_id = encounter_id
    obs.obs_datetime = obs_date
    obs.patient_id = patient_id
    obs.concept_id = Concept.find_by_name(concept_name).id
    obs.value_coded = Concept.find_by_name(value_coded).id
    obs.save
  end  
     
  def decentralize
    if request.method == :post
      unless params[:location] == "Zomba Central Hospital"
        encounter = Encounter.new()
        encounter.encounter_type = EncounterType.find_by_name("Decentralize patient").id
        encounter.encounter_datetime = session[:encounter_datetime]
        encounter.patient_id = session[:patient_id]
        encounter.save
        
        obs = Observation.new()
        obs.encounter = encounter
        obs.obs_datetime = encounter.encounter_datetime
        obs.patient_id = encounter.patient_id
        obs.concept_id = Concept.find_by_name("Transfer out destination").id
        obs.value_numeric = Location.find_by_name(params[:location]).location_id
        obs.save
        flash[:notice] = "Patient 'decentralized' to:</br>#{params[:location]}"
        redirect_to :action => "menu" and return
      else
        flash[:notice] = "Patient can not be 'decentralize' to:</br>#{params[:location]}"
        redirect_to :action => "menu" and return
      end  
    else  
      locations = Location.find(:all,:conditions =>["location_id < 1000"]).collect{|l|l.name}.compact
      @locations = ["",""]
      @locations[1] = Location.current_location.name
      if @locations[1] == "Zomba Central Hospital"
        ["Matawale Urban Health Centre","Domasi Rural Hospital","Zomba Prison Dispensary",
        "Zomba Central Hospital(HCW)","Likangala Health Centre","Chipini Health Centre","Bimbi Health Centre",
        "Nkasala Health Centre","Matiya Health Centre","Pirimiti Health Centre","Mayaka Health Centre","Thondwe Dispensary",
        "Chilipa Health Centre (Zomba)","Lambulira Health Centre","Magomero Health Centre","Namasalima Health Centre (Zomba)",
        "H Parker Sharp Dispensary","Chamba Dispensary (Zomba)"].sort.collect{|l|@locations << l}
      end

      locations.map{|l|
        next if @locations.include?(l)
        @locations << l
      }
    end
  end

  def reassign_national_id
    unless session[:patient_program].blank?
      redirect_to :action => "retrospective_data_entry_menu" and return
    end  
    @patients = Patient.find(:all,
        :joins => "INNER JOIN patient_identifier i ON patient.patient_id = i.patient_id",
        :conditions =>["identifier = ?",params[:identifier]])
    @identifier = params[:identifier]

    render :layout => false
  end

  def assign_national_id
    patient = Patient.find(params[:id])
    identifiers = PatientIdentifier.find(:all,:conditions => ["identifier_type = 1 AND voided = 0 AND patient_id = ?",patient.id]) 
    identifiers.each do |identifier|
      identifier.voided = 1
      identifier.voided_by = User.current_user.id
      identifier.date_voided = session[:encounter_datetime]
      identifier.void_reason = "Assigned new id"
      identifier.save
    end
    new_national_id = GlobalProperty.find_by_property("print_new_national_id").property_value rescue 'false'
    patient.set_new_national_id if new_national_id == 'true' and session[:patient_program].blank?
    patient.set_national_id 
    print_and_redirect("/label/national_id/#{patient.id}", "/patient/menu") and return 
  end

end
