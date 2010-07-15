class ReportsController < ApplicationController

	caches_page :virtual_art_register, :missed_appointments, :defaulters, 
              :height_weight_by_user, :monthly_drug_quantities, :survival_analysis, :old_cohort
           
  def index
    redirect_to :action => "select"
  end
  # Example report code created with Priscilla
  def height_weight_by_user
    @height_weight_encounters = Hash.new(0)
    EncounterType.find_by_name("Height/Weight").encounters.collect{|e|@height_weight_encounters[e.provider.name] += 1}
  end


  def self.sample_weight_counter
    total = 0
    return Patient.find(:all)[10..20].collect{|patient| 
      weight_observations = patient.observations.find_by_concept_name("Weight")
      unless weight_observations.first.nil?
        weight_observation_date = weight_observations.first.obs_datetime
        total += 1 if weight_observation_date > Date.new(2007,1,1).to_time
        if weight_observation_date > Date.new(2007,1,1).to_time
          weight_observation_date
        else
          "not match #{weight_observations.first.obs_datetime.to_s}"
        end
      end
    }
  end
  
  def select_cohort

    # this action sets up the form that lists all of the available quarters
    # after selecting one it sends it to the cohort action below
  
    #change start date to be the earliest observation in the database (this is on x4k's computer but not in svn)
    #@start_date = Date.new(2003,2,2)
    #@start_date = Encounter.find(:first, :order => 'encounter_datetime', :conditions => 'encounter_datetime is not NULL and encounter_datetime <> \'0000-00-00\'').encounter_datetime
    #@end_date = Date.today
    
    user = User.find(session[:user_id])
    @user_is_superuser = user.has_role('superuser')

    if params[:id]
			report_period = params[:id].sub(/\s/, "_")
			redirect_to "/reports/cohort/#{report_period}" and return 
    end

    @cached_cohort_quarters = Report.cached_cohort_quarters

    render :layout => "application" #this forces the default application layout to be used which gives us the touchscreen toolkit
  end
  
  def select_period
    user = User.find(session[:user_id])
    @user_is_superuser = user.has_role('superuser')

    if params[:id]
      report_period = params[:id].sub(/\s/, "_")
      report_name = params[:name] rescue 'cohort'
      redirect_to "/reports/#{report_name}/#{report_period}" and return 
    end

    render :layout => "application" 
  end
  
  def set_cohort_date_range
    if params[:start_year].nil? or params[:end_year].nil?
      @needs_date_picker = true
      day=Array.new(31){|d|d + 1 } 
      unknown=Array.new
      unknown[0]= "Unknown" 
      days_with_unknown = day << "Unknown"
      @days = [""].concat day

      @monthOptions = "<option>" "" "</option>"
  1.upto(12){ |number| 
       @monthOptions += "<option value = '" + number.to_s + "'>" + Date::MONTHNAMES[number] + "</option>"
      }
      @monthOptions << "<option>" "Unknown" "</option>"

      @min_date = Encounter.find(:first, :order => 'encounter_datetime').encounter_datetime.to_date 
      render :layout => "application" 
    else
      start_date = "#{params[:start_year]}-#{params[:start_month]}-#{params[:start_day]}"
      end_date = "#{params[:end_year]}-#{params[:end_month]}-#{params[:end_day]}"
      redirect_to :action => "cohort", :id => params[:id], :start_date => start_date, :end_date => end_date
    end
  end

  def cohort_trends
=begin
    redirect_to :action => 'select_cohort' and return if params[:id].nil?
    @data_hash = Hash.new
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])  

    @quarter_start = Encounter.find(:first, :order => 'encounter_datetime').encounter_datetime.to_date if @quarter_start.nil?
		@quarter_end = Date.today if @quarter_end.nil?

    @quarter_start = params[:start_date].to_date unless params[:start_date].nil?
    @quarter_end = params[:end_date].to_date unless params[:end_date].nil?
=end

    @short_name = params[:id]
    @name = CohortReportField.find_by_short_name(@short_name).name rescue nil
    render :text => "Cannot show data for: <b>#{@short_name}</b><br/> <button onmousedown='javascript:history.go(-1)'>Return</button>" unless @name
    @cumulative_trends = CohortReportFieldValue.find_all_by_short_name(@short_name, 
                                                                       :conditions => ['start_date = ?', '1900-01-01'], 
                                                                       :group => 'end_date', :order => 'end_date')
    @quarterly_trends  = CohortReportFieldValue.find_all_by_short_name(@short_name, 
                                                                       :conditions => ['start_date != ?', '1900-01-01'], 
                                                                       :group => 'end_date', :order => 'end_date')

  end

  def cohort

    redirect_to :action => 'select_cohort' and return if params[:id].nil?
    
    user = User.find(session[:user_id]) rescue nil
    @user_is_superuser = user.has_role('superuser') rescue false

    @data_hash = Hash.new
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])  

    @quarter_start = Encounter.find(:first, :order => 'encounter_datetime').encounter_datetime.to_date if @quarter_start.nil?
		@quarter_end = Date.today if @quarter_end.nil?

    @quarter_start = params[:start_date].to_date unless params[:start_date].nil?
    @quarter_end = params[:end_date].to_date unless params[:end_date].nil?
    @cumulative_start = '1900-01-01'.to_date

    if params[:id] != "Other"
#      if Location.current_arv_code  == 'LLH'
#        cohort_report = Reports::CohortByStartDate.new(@quarter_start, @quarter_end)
#      else
        cohort_report = Reports::CohortByRegistrationDate.new(@quarter_start, @quarter_end)
#      end
      cohort_report.clear_cache if params['refresh']
      @quarterly_values = cohort_report.report_values
      cohort_report.save(@quarterly_values)

      # backwards compatibilty
      @quarterly_values['messages'] = []
      @quarterly_values['occupations'] = Hash.new(0)
      @quarterly_values['start_reasons'] = Hash.new(0)
      @quarterly_values['start_reasons'] = Hash.new(0)

      # debug
      @cohort_patient_ids = {:all => [],
                                   :occupations => {},
                                   :start_reasons => {},
                                   :outcome_data => {},
                                   :of_those_on_art => {},
                                   :of_those_who_died => {}
                             }
      @cohort_patient_ids[:all] = PatientRegistrationDate.find(:all,
                                    :joins => 'LEFT JOIN patient_identifier ON
                                               patient_identifier.patient_id = patient_registration_dates.patient_id
                                               AND identifier_type = 18 AND voided = 0',
                                    :conditions => ["DATE(registration_date) >= ? AND DATE(registration_date) <= ?",
                                                    @quarter_start, @quarter_end],
                                    :order => 'CONVERT(RIGHT(identifier, LENGTH(identifier)-3), UNSIGNED)').map(&:patient_id)

    else
      @cumulative_start = @quarter_start
    end
    
#    if Location.current_arv_code  == 'LLH'
#      cumulative_report = Reports::CohortByStartDate.new(@cumulative_start, @quarter_end)
#    else
      cumulative_report = Reports::CohortByRegistrationDate.new(@cumulative_start, @quarter_end)
#    end
    cumulative_report.clear_cache if params['refresh']
    @cumulative_values = cumulative_report.report_values
    cumulative_report.save(@cumulative_values)
    @names_to_short_names = cumulative_report.names_to_short_names
    @sort_weights = cumulative_report.names_to_sort_weights
    @cumulative_values['patients_with_unknown_outcomes'] = cumulative_report.patients_with_unknown_outcome.length

    render :layout => false and return if params[:id] == "Other"

    survival_analysis

    render :layout => false
  end

  def paediatric_cohort

    redirect_to :action => 'select_cohort' and return if params[:start_date].nil?

    user = User.find(session[:user_id]) rescue nil
    @user_is_superuser = user.has_role('superuser') rescue false

    @data_hash = Hash.new
    
    @quarter_start = params[:start_date].to_date unless params[:start_date].nil?
    @quarter_end = params[:end_date].to_date unless params[:end_date].nil?
    @cumulative_start = '1900-01-01'.to_date
    
    report = Reports::CohortByRegistrationDate.new(@quarter_start, @quarter_end)
    report.clear_cache if params['refresh']
    @report_values = Hash.new(0)
    @report_values['children_started_on_arv_therapy'] = report.children_started_on_arv_therapy.length
    @report_values['infants_started_on_arv_therapy']  = report.infants_started_on_arv_therapy.length
    @report_values['new_children']  = report.new_children.length
    regimens = report.children_regimens
    regimen_breakdown = Hash.new(0)
    regimens.map do |concept_id,number|
      regimen_breakdown[(Concept.find(concept_id).name rescue "Other Regimen")] = number
    end
    @report_values['first_line_children'] = regimens[450]
    @report_values['first_line_alternative_children'] = regimens[451]+regimens[452]+regimens[458] rescue 0
    @report_values['second_line_children'] = regimen_breakdown['Zidovudine Lamivudine Tenofovir Lopinavir/Ritonavir Regimen'] +
                                             regimen_breakdown['Didanosine Abacavir Lopinavir/Ritonavir Regimen']  rescue 0

    @report_values['defaulters'] = report.children_outcomes[373]

  end

  def cohort_start_reasons
    @cohort_values = Hash.new(0)
    @cohort_values['messages'] = []
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])
    
    start_reasons = Reports::CohortByRegistrationDate.new(@quarter_start, @quarter_end).start_reasons
    @cohort_values['start_reasons'] = start_reasons[0]
    @cohort_values["start_cause_EPTB"] = start_reasons[0]['start_cause_EPTB']
    @cohort_values["start_cause_PTB"] = start_reasons[0]['start_cause_PTB']
    @cohort_values["start_cause_APTB"] = start_reasons[0]['start_cause_APTB']
    @cohort_values["start_cause_KS"] = start_reasons[0]['start_cause_KS']
    @cohort_values["pmtct_pregnant_women_on_art"] = start_reasons[0]['pmtct_pregnant_women_on_art']

    # debug 
    @cohort_patient_ids = {:all => [],
                                 :occupations => {},
                                 :start_reasons => {},
                                 :outcome_data => {},
                                 :of_those_on_art => {},
                                 :of_those_who_died => {}
                           }
    @cohort_patient_ids[:all] = PatientRegistrationDate.find(:all, 
                                  :joins => 'LEFT JOIN patient_identifier ON  
                                             patient_identifier.patient_id = patient_registration_dates.patient_id 
                                             AND identifier_type = 18 AND voided = 0',
                                  :conditions => ["registration_date >= ? AND registration_date <= ?", 
                                                  @quarter_start, @quarter_end], 
                                  :order => 'CONVERT(RIGHT(identifier, LENGTH(identifier)-3), UNSIGNED)').map(&:patient_id)

    @cohort_patient_ids[:start_reasons] = start_reasons[1] 

    render :layout => false
  end

  def cohort_art_regimens
    @cohort_values = Hash.new(0)
    @cohort_values['messages'] = []
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])

    regimen_types = Reports::CohortByRegistrationDate.new(@quarter_start, @quarter_end).regimen_types
    @cohort_values['regimen_types'] = regimen_types[0]
    @cohort_values['regimen_breakdown'] = regimen_types[1]
    render :layout => false
  end

  def cohort_outcomes
    @cohort_values = Hash.new(0)
    @cohort_values['messages'] = []
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])

    @cohort_values['outcomes'] =  Reports::CohortByRegistrationDate.new(@quarter_start, @quarter_end).old_outcomes
    @cohort_values['alive_on_ART_patients'] = @cohort_values['outcomes']['alive_on_ART_patients']
    @cohort_values['dead_patients'] = @cohort_values['outcomes']['dead_patients']
    @cohort_values['defaulters'] = 0 #@cohort_values['outcomes']['defaulters']
    @cohort_values['art_stopped_patients'] = @cohort_values['outcomes']['art_stopped_patients']
    @cohort_values['transferred_out_patients'] = @cohort_values['outcomes']['transferred_out_patients']



    render :layout => false
  end

  # Stand alone Survival Analysis page. use this to run Survival Analysis only, without cohort
  #
  def survival_analysis
    redirect_to :action => 'select_cohort' and return if params[:id].nil?
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])  
    
    cohort_report = Reports::CohortByRegistrationDate.new(@quarter_start, @quarter_end)
    #cohort_report = Reports::CohortByStartDate.new(@quarter_start, @quarter_end)
    @survivals = cohort_report.survival_analysis
    @child_survivals = cohort_report.children_survival_analysis

    @messages = []
  end

  def reception
    @all_people_registered = Patient.find(:all, :conditions => "voided = 0")
    @total_people_registered_with_filing_numbers  = 0
    @all_people_registered.each{|person|
      @total_people_registered_with_filing_numbers += 1 unless person.filing_number.nil?
    }
    @people_registered_today = Patient.find(:all, :conditions => ["voided = 0 AND DATE(date_created) = ?", Date.today])
    @total_people_registered_with_filing_numbers_today = 0
    @people_registered_today.each{|person|
      @total_people_registered_with_filing_numbers_today += 1 unless person.filing_number.nil?
    }
  end
  
  def data
    @all_people_registered = Patient.find(:all, :conditions => "voided = 0")
    @total_people_registered_with_filing_numbers  = 0
    @all_people_registered.each{|person|
      @total_people_registered_with_filing_numbers += 1 unless person.filing_number.nil?
    }
    @people_registered_today = Patient.find(:all, :conditions => ["voided = 0 AND DATE(date_created) = ?", Date.today])
    @total_people_registered_with_filing_numbers_today = 0
    @people_registered_today.each{|person|
      @total_people_registered_with_filing_numbers_today += 1 unless person.filing_number.nil?
    }
  end
  
  def missed_appointments
    # This report is not accurate and needs to be re-written with patient_defaulter_dates
    render :text => 'Report disabled. <a href="/reports">Back to Reports</a>'
    return
=begin
     @patient_appointments = Patient.find(:all).collect{|pat|
      next if pat.date_started_art.nil?; 
      next if pat.outcome.name =~/Died|Transfer|Stop/ rescue nil
      next if pat.drug_orders.nil? or pat.drug_orders.empty?
      next if pat.next_appointment_date and pat.next_appointment_date.to_time > Date.today.to_time;
      pat
    }.compact
    render:layout => true;
=end
  end

  def defaulters
    @defaulters = Patient.art_patients(:include_outcomes => [Concept.find_by_name("Defaulter")])
  end
  
  def select
    if params[:report]
      case  params[:report]
        when "Patient register"
           redirect_to :action => "virtual_art_register"
           return
        when "Cohort"
           redirect_to :action => "select_cohort"
           return
        when "Survival Analysis"
           redirect_to :action => 'survival_analysis', :id => 'Q3+2008'
           return
        when "Missed appointments"
           redirect_to :action => "missed_appointments"
           return
        when "Defaulters"
           redirect_to :action => "defaulters"
           return
        when "Drug quantities"
           redirect_to :action => "select_monthly_drug_quantities"
           return
        when "User stats"
           redirect_to :action => "stats_date_select",:id => "stats_menu"
           return
        when "Appointment dates"
           redirect_to :action => "app_dates_date_selector"
           return
        when "Bwaila/MPC patients"
           redirect_to :action => "stats_date_select",:id => "genrept_hiv_reception"
           return
        when "Change appointment dates"
           redirect_to :action => "set_date",:view_month_only => true
           return
      end
    end

   render:layout => "application";
  end

	def virtual_art_register
		# delete cache report if ?refresh appended to url
		#expire_page :action => "virtual_art_register" unless params[:refresh].nil? 

		@patients=Patient.virtual_register
		@i = @patients.length
		redirect_to :action =>"virtual_art_register" and return if @patients.nil?
		@quarter=(Time.now().month.to_f/3).ceil.to_s
		render(:layout => false)
  end
  
  def download_virtual_art_register
     @patients = Patient.virtual_register
     csv_string = FasterCSV.generate{|csv|
       csv << ["ARV #","Qrtr","Reg Date","Name","Sex","Age","Occupation","ART Start date","Start Reason","PTB","EPTB","KS","PMTCT","Outcome","Reg.","Ambulant","Work/School","Weight at Starting","Weight at last visit","Peripheral neuropathy","Hepatitis","Skin rash","Lactic acidosis"," Lipodistrophy","Anaemia","Other side effect","Remaining tablets"]
       counter = 0
       @patients.sort {|a,b| a[1].arv_registration_number[4..-1].to_i <=> b[1].arv_registration_number[4..-1].to_i }.each do |hash_key,visits | 
       counter += 1
       csv << [visits.arv_registration_number,visits.quarter,visits.date_of_registration,visits.name,visits.sex, visits.age,visits.occupation, visits.date_of_art_initiation,visits.reason_for_starting_arv,visits.ptb, visits.eptb, visits.kaposissarcoma, visits.refered_by_pmtct,visits.outcome_status,visits.arv_regimen, visits.ambulant,  visits.at_work_or_school,visits.last_weight,visits.first_weight,visits.peripheral_neuropathy,visits.hepatitis,visits.skin_rash,visits.lactic_acidosis,visits.lipodystrophy,visits.anaemia,visits.other_side_effect,visits.tablets_remaining]
       end unless @patients.nil?
     
     }
     file_name ="#{Time.now}_virtual_patient_register.csv"
     send_data(csv_string,
      :type => 'text/csv; charset=utf-8; header=present',
      :filename => file_name)
  end
  
  def pill_counts
    @patients = Patient.find(:all)
  end

  def select_monthly_drug_quantities
    if params[:report_year] and params[:report_month]
			redirect_to "/reports/monthly_drug_quantities/#{params[:report_year]}_#{params[:report_month]}"
      return 
    end
    render :layout => "application"
  end

  def monthly_drug_quantities
    year_month = []
    if params[:id].nil?
      redirect_to(:action => action_name, 
                  :id => "#{Date.today.year}_#{Date.today.month}")
      return
    end 
    year_month = params[:id].split("_") || nil
    @year = year_month[0].to_i || Date.today.year
    @month = year_month[1].to_i || Date.today.month

    @month_names = {1 => "Jan", 2 => "Feb", 3 => "Mar", 4 => "Apr", 5 => "May",
                    6 => "Jun", 7 => "Jul", 8 => "Aug", 9 => "Sep", 10 => "Oct",
                    11 => "Nov", 12 => "Dec"}

    # create drug hash
    @drug_quantities = Hash.new
    Drug.find(:all).each{|drug|
      @drug_quantities[drug.name] = drug.month_quantity(@year, @month)
    }

    @drug_quantities = @drug_quantities.sort{|a,b| a[0] <=> b[0]}
  end

  def cohort_patients
  end

  def cohort_debugger
    @report_type = params[:report_type] 
    quarter = @report_type.split(":")[1].strip rescue nil
    @path = "cohort_tool|reports|non-eligible_patients_in_cohort|#{quarter}"
    cohort_patient_ids = params[:cohort_patient_ids] || session[:cohort_patient_ids] rescue nil
    @key = :all
    @field = ''
    @title = nil

    start_date = params[:start_date] rescue nil
    end_date = params[:end_date] rescue nil

    extra_param_keys = request.query_parameters.keys - ['start_date', 'end_date']
    
    # for new format
#    if Location.current_arv_code  == 'LLH' and start_date == '1900-01-01'
#      cohort = Reports::CohortByStartDate.new(start_date.to_date, end_date.to_date)
#    else
      cohort = Reports::CohortByRegistrationDate.new(start_date.to_date, end_date.to_date)
#    end
    @cohort_end_date = end_date.to_date rescue nil
    debug_method = nil
    if cohort.methods.include?(params[:id])
      debug_method = params[:id]
    else
      debug_method = cohort.short_name_to_method[params[:id]]
    end
    if debug_method
      debug_params = debug_method.split(',')
      debug_params << params[:outcome_end_date] if params[:outcome_end_date]
      debug_params << params[:min_age] if params[:min_age]
      debug_params << params[:max_age] if params[:max_age]
      
      param_count = debug_params.length - 1
      if param_count == 0
        @patients = cohort.send debug_method
      elsif param_count == 1
        @patients = cohort.send debug_params[0], debug_params[1]
      elsif param_count == 2
        @patients = cohort.send debug_params[0], debug_params[1], debug_params[2]
      elsif param_count == 3
        @patients = cohort.send debug_params[0], debug_params[1], debug_params[2], debug_params[3]
      elsif param_count == 4
        @patients = cohort.send debug_params[0], debug_params[1], debug_params[2],
                                debug_params[3], debug_params[4]
      end
      @title = CohortReportField.find_by_short_name(params[:id]).name rescue nil

      render :layout => false
      return
    elsif params[:id].include?(',')
      debug_params = params[:id].split(',')
      param_count = debug_params.length - 1
      if param_count == 0
        @patients = cohort.send debug_method
      elsif param_count == 1
        @patients = cohort.send debug_params[0], debug_params[1]
      elsif param_count == 2
        @patients = cohort.send debug_params[0], debug_params[1], debug_params[2]
      end
      render :layout => false
      return
    end

    if params[:cohort_patient_ids] #use all ids from params
      @key = params[:id].to_sym
      @field = params[:field]
      @patients = cohort_patient_ids.split(',')
      @filter = params[:filter]
      render:layout => false
      return
    elsif params[:id] and params[:field] and start_date and end_date
      cohort = Reports::CohortByRegistrationDate.new(start_date.to_date, end_date.to_date)
      @key = params[:id].to_sym
      @field = params[:field]
      
      dead_patients = cohort.patients_with_outcomes('Died')
      transfer_out_patients = cohort.patients_with_outcomes('Transfer out,Transfer Out(With Transfer Note),Transfer Out(Without Transfer Note)'.split(','))
      stopped_patients = cohort.patients_with_outcomes('ART stop')
      deffaulted_patients = cohort.patients_with_outcomes('Defaulter')

      case params[:id]
      when 'occupations'
        if @field == 'soldier/police'
          @field = 'solder,police'
          @patients = cohort.patients_with_occupations(@field.gsub("/", ' ').split(','))
        else
          @patients = cohort.patients_with_occupations(@field.split(','))
        end
          @field = params[:field]
      when 'regimen_types'
          @patients = cohort.find_all_patient_art_regimens(@field.gsub('_',' '))
          @patients = @patients - (dead_patients + transfer_out_patients + stopped_patients + deffaulted_patients)
      when 'outcome'
          if @field == 'transferred_out'
             @patients = transfer_out_patients
          elsif @field == 'alive_on_art'
            on_art_patients = cohort.patients_with_outcomes('On ART')
            @patients = on_art_patients - (dead_patients + transfer_out_patients + stopped_patients + deffaulted_patients)
          else
            @patients = cohort.patients_with_outcomes(@field.gsub('_', ' ').split(','))
          end
      when 'of_those_on_art'
        if @field == 'ambulatory'
          names_to_ids = {'ambulatory' => Concept.find_by_name('Is able to walk unaided').id}
          @patients = cohort.find_patients_with_last_observation([names_to_ids[@field]])
        elsif @field == 'at_work_or_school'
          names_to_ids = {'at_work_or_school' => Concept.find_by_name('Is at work/school').id}
          @patients = cohort.find_patients_with_last_observation([names_to_ids[@field]])
        elsif @field == 'side_effects_patients'
          concept_ids = []
          side_effects = ['Skin rash','Hepatitis','Peripheral neuropathy']
          side_effects.each{|name|
            concept_ids << Concept.find_by_name(name).id
          }
          names_to_ids = {'side_effects_patients' => concept_ids}
          @patients = cohort.find_patients_with_last_observation([names_to_ids[@field]])
        elsif @field == 'on_1st_line_with_pill_count_adults'
          @patients = cohort.adults_on_first_line_with_pill_count
        elsif @field == 'adherent_patients'
          @patients = cohort.adults_on_first_line_with_pill_count_with_eight_or_less
        end
      when 'of_those_who_died'
        @patients = cohort.find_all_dead_patients(@field)
      end
    elsif cohort_patient_ids
      @patients = cohort_patient_ids[:all]
    else
      render :text => "Error: Could not get the list of patients to debug. <a href='javascript:history.back();'>Back</a>"
      return
    end

    render:layout => false
  end

  def select_duplicate_identifiers
    render(:layout => "layouts/menu")
  end

  def duplicate_identifiers
    error_text = "Missing a Patient Identifier Type ID<br/>"
    error_text += "e.g. <a href='/reports/duplicate_identifiers/18'>Duplicate ARV Numbers</a>"
    render :action => 'select_duplicate_identifiers' and return if params[:id].nil?

    identifier_type = PatientIdentifierType.find(params[:id].to_i)
    @identifiers = PatientIdentifier.duplicates_by_type(identifier_type)
    @title = identifier_type.name
  end

  def select_missing_identifiers
    render(:layout => "layouts/menu")
  end

  def missing_identifiers
    error_text = "Missing a Patient Identifier Type ID<br/>"
    error_text += "e.g. <a href='/reports/missing_identifiers/18'>Missing ARV Numbers</a>"
    #render :text => error_text and return if params[:id].nil?
    render :action => 'select_missing_identifiers' and return if params[:id].nil?
    
    identifier_type = PatientIdentifierType.find(params[:id].to_i)
    @title = identifier_type.name
    
    hiv_program_id = Program.find_by_name('HIV').id
    art_patients = Patient.find(:all, :joins => [:programs], :conditions => ['patient_program.program_id = ? ', hiv_program_id])
    patients_with_identifier = Patient.find(:all, :joins => [:patient_identifiers], :conditions => ['patient_identifier.identifier_type = ?', identifier_type.id])
    @patients = art_patients - patients_with_identifier
  end

  def invalid_visits
    #
    # Needs a way to filter encounters e.g. by Qtr or month
    #
    dates = Encounter.find(:all, :select => 'DATE(encounter_datetime) as date', :group => 'DATE(encounter_datetime)').map(&:date)
    @patients_by_date = Hash.new([])
    dates.each{|date|
      @patients_by_date[date] << Encounter.invalid_visit_patients(date)
    }
  end

  def missing_visits
    (@start_date, @end_date) = Report.cohort_date_range(params[:id])  

    hiv_program_id = Program.find_by_name('HIV').id
    encounter_type_id = params[:type].to_i
    encounter_type_id = 3 if encounter_type_id < 1
    encounter_type = EncounterType.find(encounter_type_id) rescue nil
    @title = encounter_type.name rescue ''

    all_patients = Patient.find(:all, 
                                :joins => "INNER JOIN patient_program ON patient_program.patient_id = patient.patient_id
                                           INNER JOIN (SELECT patient_id, MIN(encounter_datetime) AS first_visit_date 
                                                       FROM encounter 
                                                       GROUP BY patient_id
                                                      ) AS first_encounters ON first_encounters.patient_id = patient.patient_id",
                                :conditions => ['patient.voided = ? AND patient_program.program_id = ? AND 
                                                 first_visit_date >= ? AND  
                                                 first_visit_date <= ?', 
                                                 0, 1, @start_date, @end_date], 
                                :group => 'patient_id')
    all_patients = all_patients.delete_if{|patient| patient.reason_for_art_eligibility.nil?}
    patients_without_drugs = encounter_type.encounters.find(:all, :group => 'patient_id').map(&:patient) rescue []
    @patients = all_patients - patients_without_drugs
  end

  def supervision
    render(:layout => "layouts/menu")
  end

  def stats_date_select
    @form_action = params[:id]
  end
  
  def stats_menu
    username = params[:user][:username] rescue nil
    username = params[:username] if username.blank?
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    @stats_data = Report.user_stat_data(@start_date,@end_date,username)
    @user = User.find_by_username(username) rescue nil
    @totals = Hash.new(0)
    @stats_data.each{|key,value|
      value.split(";").each{|x|
        total_per_day = x.split(":")[1]
        @totals[key]+=total_per_day.to_i
      }
    }
  end

  def show_stats
    @user = User.find(params[:user_id]) rescue nil
    @stats_name = params[:stats_name]
    @results = Report.stats_to_show(params[:id])
  end
  
  def user_stats_graph
    @encounter_count = params[:id]
    @stats_name = params[:stat_name]
    @date = params[:date]
    @user_name = params[:user_name]
  end

  def genrept_hiv_reception
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    @stats_data = Report.genrept_hiv_reception(@start_date,@end_date)
  end

  def appointment_dates
    @date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @visit_day = params[:visit_day]
    @patients = Report.appointment_dates(@date)
    render(:layout => "layouts/menu")
  end

  def set_date
    @needs_date_picker = true
    @date = params[:date]
    @id = params[:id]
    @view_month_only = params[:view_month_only]
    @change_appointment_date = "change_appointment_date"  
    @change_appointment_date = "confirmed_appointment_dates" if @view_month_only 
  end

  def change_appointment_date
    new_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    patient = Patient.find(params[:patient_id])
    patient.change_appointment_date(params[:from_date].to_date,new_date)
    redirect_to :action =>"appointment_dates",:start_year => params[:from_date].to_date.year ,:start_month => params[:from_date].to_date.month,:start_day => params[:from_date].to_date.day
  end

  def data_cleaning
    render(:layout => "layouts/menu")
  end

  def dispensations_without_prescriptions
    (@start_date, @end_date) = Report.cohort_date_range(params[:id])
    cohort = Reports::CohortByRegistrationDate.new(@start_date,@end_date)
    @dispensations_without_prescriptions = cohort.dispensations_without_prescriptions
  end

  def prescriptions_without_dispensations
    (@start_date, @end_date) = Report.cohort_date_range(params[:id])
    cohort = Reports::CohortByRegistrationDate.new(@start_date,@end_date)
    @prescriptions_without_dispensations = cohort.prescriptions_without_dispensations
  end
  
  def patients_with_multiple_start_reasons
    (@start_date, @end_date) = Report.cohort_date_range(params[:id])
    cohort = Reports::CohortByRegistrationDate.new(@start_date,@end_date)
    @patients = cohort.patients_with_multiple_start_reasons
  end

  def patients_with_adherence_greater_than_hundred
    @patients = CohortTool.adherence_over_hundred(params[:id])
    @report_type =  "Patient with adherence greater than 100"
    @quater =  params[:id] + ": (#{@patients.length})" rescue  params[:id]
    return
  end

  def missed_appointments
    session[:list_of_patients] = Report.missed_appointments(params[:date])
    redirect_to :controller => "cohort_tool" ,:action => "list",
    :report_type => "#{params[:date].to_date.strftime("%d-%b-%Y")} missed appointments patient list"
  end

  def confirmed_appointment_dates
    @month = "01-#{params[:start_month]}-#{Date.today.year}".to_date.strftime("%B")
    @results = Report.confirmed_appointment_dates_to_show(params[:start_month])
  end

  def set_appointment_date
    @month = params[:month]
    @date = params[:date].to_date.strftime("%A,  %d-%B-%Y")
    render(:layout => "layouts/menu")
  end

  def set_new_app_date
    patient = Patient.find_by_national_id(params[:id]).last rescue nil
    render :text => "Patient with ID: #{params[:id]} not found!</br>Change of appointment not done." and return if patient.blank?
    current_date =  session[:encounter_datetime].to_date rescue Date.today
    patient.change_appointment_date(true,nil,params[:date].to_date)

    html = <<EOF
<Table>
<tr><td class='headings'>Name:</td><td>&nbsp;#{patient.name}</td></tr>
<tr><td class='headings'>New appointment date:</td><td>&nbsp;#{params[:date].to_date}</td></tr>
<tr><td class='headings'>Print visit summary label:</td><td>&nbsp;<button id='visit_day_button' onmousedown="document.location='/label/mastercard_visit/?id=#{patient.id}&date=#{current_date}'">Print</button></td></tr>
</Table>
EOF
    render :text => html and return 
  end

end


