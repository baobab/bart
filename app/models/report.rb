class Report < OpenMRS
  set_table_name "report"
  belongs_to :user, :foreign_key => :user_id
  set_primary_key "report_id"

  cattr_accessor :cohort_patient_ids

  Report.cohort_patient_ids = {:all => [],
                            :occupations => {},
                            :start_reasons => {},
                            :outcome_data => {},
                            :of_those_on_art => {},
                            :of_those_who_died => {}
  }

  def self.cache
    #TODO fix this so that it uses render_to_string instead of wget
    # these need to be added to controllers/application to make sure logins aren't required
    # These are all URLs that should be cached
    q="Q2+" + Date.today.year.to_s
    q2="Q1+" + Date.today.year.to_s
    q3="Q4+" + (Date.today.year - 1).to_s
    q4="Q3+"  + (Date.today.year - 1).to_s
    q5="Q2+"  + (Date.today.year - 1).to_s
    q6="Q3+" + Date.today.year.to_s

    urls = [
           "reports/cohort/Cumulative",
           "reports/virtual_art_register",
           "reports/monthly_drug_quantities",
          # These reports are crashing. Test them before enabling
          # "reports/missed_appointments",
          # "reports/height_weight_by_user",
           "reports/defaulters",
           "reports/cohort/#{q}",
           "reports/cohort/#{q2}",
           "reports/cohort/#{q3}",
           "reports/cohort/#{q4}",
           "reports/cohort/#{q5}",
           "reports/cohort/#{q6}"
           ]

    #base_url = request.env["HTTP_HOST"]
    base_url = "localhost"
    base_url += ":3000" if RAILS_ENV == "development"
    @urls = Hash.new

    urls.each{|report_url|
      #public_path = "cached/#{report_url}.html"
      #public_path.gsub!(/\?/, "_")
      #public_path.gsub!(/%20/, "_")
      #output_document = "#{RAILS_ROOT}/public/#{public_path}"
      output_document = "/tmp/bart_last_cached_report.html"
      original_url = "http://#{base_url}/#{report_url}"
      #cached_url = "http://#{base_url}/#{public_path}"
      clear_cached_report_command = "mv #{RAILS_ROOT}/public/#{report_url}.html #{RAILS_ROOT}/public/#{report_url}+old.html"
      command = "wget --timeout=0 --output-document #{output_document} #{original_url}?refresh=true"
      #command = "wget --timeout=5000  #{original_url}?refresh=true"
      #@urls[original_url] = cached_url
# Start this in a thread, otherwise we can block the whole app (depending on how concurrency is setup)
      Thread.new{
        #yell "#{command}"
        #yell `#{command}`
        `#{clear_cached_report_command}`
        `#{command}`
      }
    }

  end

  def self.survival_analysis_hash(survival_patients, start_date, end_date, outcome_end_date, count)
    registration_start_date = start_date
    registration_end_date = end_date
    outcome_end_date = outcome_end_date
    outcomes = Hash.new

    outcomes["Defaulted"] = 0
    outcomes["On ART"] = 0
    outcomes["Died"] = 0
    outcomes["ART Stop"] = 0
    outcomes["Transfer out"] = 0

    # TODO: Optimise. Loop through all patients once and assign each art patient
    # to an approproate Survival entry without breaking @outcomes['Total']
    #@patients = all_patients.collect{|patient| 
    #  start_date = patient.date_started_art
    #  patient if start_date and 
    #             start_date.between?(registration_start_date.to_time, registration_end_date.to_time)
    #}.compact

    outcomes["Title"] = "#{count*12} month survival: outcomes by end of #{outcome_end_date.strftime('%B %Y')}"
    outcomes["Total"] = survival_patients.length
    outcomes["Start Date"] = start_date
    outcomes["End Date"] = end_date
    
    survival_patients.each{|patient|
      patient_outcome = patient.cohort_outcome_status(registration_start_date, outcome_end_date)

      if (patient_outcome.downcase.include?("on art") and patient.defaulter?(outcome_end_date)) or patient_outcome == "Defaulter"
        outcomes["Defaulted"] += 1
      elsif patient_outcome.include?("Died")
        outcomes["Died"] += 1
      elsif patient_outcome.include?("ART Stop")
        outcomes["ART Stop"] += 1
      elsif patient_outcome.include?("Transfer")
        outcomes["Transfer out"] += 1
      elsif patient_outcome.downcase.include?("on art")
        outcomes["On ART"] += 1
      else
        if outcomes.has_key?(patient_outcome) then
          outcomes[patient_outcome] += 1
        else
          outcomes[patient_outcome] = 1
        end
      end

    }
    return outcomes
  end
 
  def self.cohort_date_range(quarter_text, start_date=nil, end_date=nil)
    quarter_end_hash = {"Q1"=>"mar-31", "Q2"=>"jun-30","Q3"=>"sep-30","Q4"=>"dec-31"}
		if quarter_text == "Cumulative"
      @quarter_start = start_date.to_date rescue nil if start_date
      @quarter_end = end_date.to_date rescue nil if end_date

      @quarter_start = Encounter.find(:first, :order => 'encounter_datetime').encounter_datetime.to_date if @quarter_start.nil?
      if @quarter_end.nil?
        @quarter_end = Date.today
        censor_date = (@quarter_end.year-1).to_s + "-" + "dec-31"

        quarter_end_hash.each{|a,b|
          break if @quarter_end < (@quarter_end.year.to_s+"-"+b).to_date
          censor_date = @quarter_end.year.to_s+"-"+b
        }
        @quarter_end = censor_date.to_date
      end

		else
			# take the cohort string that was passed in ie. "Q1 2006", split it on the space and save it as two separate variables
      quarter_text.gsub!('+',' ')
			quarter, quarter_year = quarter_text.split(" ")
      return [nil, nil] unless quarter =~ /Q[1-4]/ and quarter_year =~ /\d\d\d\d/
			quarter_month_hash = {"Q1"=>"January", "Q2"=>"April","Q3"=>"July","Q4"=>"October"}
			quarter_month = quarter_month_hash[quarter]
		 
			@quarter_start = (quarter_year + "-" + quarter_month + "-01").to_date 
			@quarter_end = (quarter_year + "-" + quarter_end_hash[quarter]).to_date
    end
    
    return [@quarter_start, @quarter_end]

  end


end

