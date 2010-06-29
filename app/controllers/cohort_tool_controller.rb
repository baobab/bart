class CohortToolController < ApplicationController

  def menu
   render :layout => false
  end

  def select
    @report_type = params[:report_type]
    if @report_type == "in_arv_number_range"
      @arv_number_start = params[:arv_number_start]
      @arv_number_end = params[:arv_number_end]
    end
  end

  def reports
    session[:list_of_patients] = nil
    if params[:report]
      case  params[:report_type]
        when "visits_by_day"
          redirect_to :action => "visit_by_day",:name => params[:report],
                      :pat_name => "Visits by day",:quater => params[:report].gsub("_"," ")
          return
        when "non-eligible_patients_in_cohort"
          date = Report.cohort_date_range(params[:report])
          redirect_to :controller =>"reports", :action => "cohort_debugger",
                      :start_date =>date.first.to_s ,:end_date =>date.last.to_s,
                      :id => "start_reason_other",:report_type =>"Non-eligible patients in: #{params[:report]}"
          return
        when "in_arv_number_range"
          redirect_to :action => "in_arv_number_range",:quater => params[:report].gsub("_"," "),
                      :arv_number_start => params[:arv_number_start],:arv_number_end => params[:arv_number_end]
          return
        when "internal_consistency_checks"
          redirect_to :action => "internal_consistency_checks",:quater => params[:report].gsub("_"," ")
          return
        when "summary_of_records_that_were_updated"
          redirect_to :action => "records_that_were_updated",:quater => params[:report].gsub("_"," ")
          return
        when "adherence_histogram_for_all_patients_in_the_quarter"
          redirect_to :action => "adherence",:quater => params[:report].gsub("_"," ")
          return
        when "patients_with_adherence_greater_than_hundred"
          redirect_to :action => "patients_with_adherence_greater_than_hundred",:quater => params[:report].gsub("_"," ")
          return
        when "patients_with_multiple_start_reasons"
          redirect_to :action => "patients_with_multiple_start_reasons",
                      :quater => params[:report].gsub("_"," "),:report_type => params[:report_type]
          return
        when "dispensations_without_prescriptions"
          redirect_to :action => "dispensations",:quater => params[:report].gsub("_"," "),:report_type => params[:report_type]
          return
        when "prescriptions_without_dispensations"
          redirect_to :action => "dispensations",:quater => params[:report].gsub("_"," "),:report_type => params[:report_type]
          return
        when "drug_stock_report"
          start_date = "#{params[:start_year]}-#{params[:start_month]}-#{params[:start_day]}"
          end_date = "#{params[:end_year]}-#{params[:end_month]}-#{params[:end_day]}"

          if end_date.to_date < start_date.to_date
            redirect_to :controller => "cohort_tool",:action => "select",
              :report_type =>"drug_stock_report"
            return  
          end rescue nil

          redirect_to :controller => "drug",:action => "report",
              :start_date => start_date,:end_date => end_date,
              :quater => params[:report].gsub("_"," ")
          return
      end
    end

  end
  
  def patients_visits_per_day
    date = params[:date].strip.to_date

    session[:list_of_patients] = CohortTool.patients_visits_per_day(date)
    redirect_to :action => "list",:total_visits_per_day => "true",
                :report_type => "Patients who came on: #{date.to_s}"
  end
    
  def dispensations
    if params[:report_type] =='dispensations_without_prescriptions'
      (start_date, end_date) = Report.cohort_date_range(params[:quater])
      cohort = Reports::CohortByRegistrationDate.new(start_date,end_date)
      @patients = cohort.missing_prescriptions #dispensations_without_prescriptions
      @quater = params[:quater] + ": (#{@patients.length})" rescue  params[:quater]
      @report_type = "Patients with missing prescriptions"
    else  
      (start_date, end_date) = Report.cohort_date_range(params[:quater])
      cohort = Reports::CohortByRegistrationDate.new(start_date,end_date)
      @patients = cohort.missing_dispensations #prescriptions_without_dispensations
      @quater = params[:quater] + ": (#{@patients.length})" rescue  params[:quater]
      @report_type = "Patients with missing dispensations"
    end 
    @path = "cohort_tool|reports|#{params[:report_type]}|#{params[:quater].gsub(' ','_')}" 
    render :layout => false
  end

  def patients_with_multiple_start_reasons
    (@start_date, @end_date) = Report.cohort_date_range(params[:quater])
    cohort = Reports::CohortByRegistrationDate.new(@start_date,@end_date)
    @patients = cohort.patients_with_multiple_start_reasons
    @quater = params[:quater] + ": (#{@patients.length})" rescue  params[:quater]
    @report_type = "Patients with multiple start reasons"
    @path = "cohort_tool|patients_with_multiple_start_reasons|patients_with_multiple_start_reasons|#{params[:quater].gsub(' ','_')}" 
    render :layout => false
  end

  def arv_number_range
    @report_type = params[:report_type]
  end

  def in_arv_number_range
    @patients = CohortTool.in_arv_number_range(params[:quater],params[:arv_number_start].to_i,params[:arv_number_end].to_i)
    @quater = params[:quater] + ": (#{@patients.length})" rescue  params[:quater]
    @report_type = "Patients within the range of #{params[:arv_number_start]} to #{params[:arv_number_end]} but not in"
    @path = "cohort_tool|in_arv_number_range|in_arv_number_range|#{params[:arv_number_start]},#{params[:arv_number_end]},#{params[:quater].gsub(' ','_')}" 
    render :layout => false
    return
  end

  def missing_adherence
    redirect_to :action => "patients_with_adherence_greater_than_hundred",
                :quater => params[:quater],:show_missing_adherence => "yes"
    return
  end

  def patients_with_adherence_greater_than_hundred
    min_range = params[:min_range]
    max_range = params[:max_range]
    missing_adherence = false
    missing_adherence = true if params[:show_missing_adherence] == "yes"
    session[:list_of_patients] = nil
    @patients = CohortTool.adherence_over_hundred(params[:quater],min_range,max_range,missing_adherence)

    @quater = params[:quater] + ": (#{@patients.length})" rescue  params[:quater]
    if missing_adherence
      @report_type = "Patient(s) with missing adherence"
    elsif max_range.blank? and min_range.blank?
      @report_type = "Patient(s) with adherence greater than 100%"
    else
      @report_type = "Patient(s) with adherence starting from  #{min_range}% to #{max_range}%"
    end  
    render :layout => false
    return
  end

  def consistency_checks 
    patients = Patient.find(:all,:conditions =>["patient_id IN (?)",params[:id].split(",")])
    quater = params[:quater] + ": (#{patients.length})" rescue  params[:quater]
    session[:list_of_patients] = CohortTool.patients_to_show(patients)
    redirect_to :action => "list",:quater => quater,:report_type => params[:report_type]
    return
  end

  def adherence
    adherences = CohortTool.adherence(params[:quater])
    @quater = params[:quater] 
    type = "patients_with_adherence_greater_than_hundred"
    @report_type = "Adherence Histogram for all patients"
    @adherence_summary = "&nbsp;&nbsp;<button onclick='adhSummary();'>Summary</button>" unless adherences.blank?
    @adherence_summary+="<input class='test_name' type=\"button\" onmousedown=\"document.location='/cohort_tool/reports?report=#{@quater}&report_type=#{type}';\" value=\"Over 100% Adherence\"/>"  unless adherences.blank?

    @adherence_summary_hash = Hash.new(0)
    adherences.each{|adherence,value|
      adh_value = value.to_i
      current_adh = adherence.to_i
      if current_adh <= 94
        @adherence_summary_hash["0 - 94"]+= adh_value
      elsif current_adh >= 95 and current_adh <= 100
        @adherence_summary_hash["95 - 100"]+= adh_value
      else current_adh > 100
        @adherence_summary_hash["> 100"]+= adh_value
      end  
    }
    @adherence_summary_hash['missing'] = CohortTool.missing_adherence(@quater).length rescue 0
    @adherence_summary_hash.values.each{|n|@adherence_summary_hash["total"]+=n}

    data = ""
    adherences.each{|x,y|data+="#{x}:#{y}:"}
    @id = data[0..-2] || ''

    @results = @id
    @results = @results.split(':').enum_slice(2).map
    @results = @results.each {|result| result[0] = result[0]}.sort_by{|result| result[0]}
    @results.each{|result| @graph_max = result[1].to_f if result[1].to_f > (@graph_max || 0)}
    @graph_max ||= 0
    render :layout => false
  end

  def list
    @patients = session[:list_of_patients]
    @quater = params[:quater] || "Total: #{@patients.length rescue 0}" 
    @report_type = params[:report_type]
    render :layout => false
  end

  def visit_by_day
    encounters = CohortTool.visits_by_day(params[:quater])
    data = ""
    encounters.each{|x,y|data+="#{x}:#{y};"}
    visit_by_days = data[0..-2] || ''
    @results = Report.stats_to_show(visit_by_days) unless visit_by_days.blank?
    @totals_by_week_day = CohortTool.totals_by_week_day(@results) unless @results.blank?
    @stats_name = "Visits by day"
    @quater = params[:quater] 
    render :layout => false
  end

  def graph
    date = Report.cohort_date_range(params[:quater])
    start_date = date.first
    end_date = date.last
   
    params[:pat_name] = params[:quater]
    params[:name] = params[:day]
    data = ""
    params[:id].split(':').enum_slice(2).map{|x,y|
      check_date = x.to_date
      next unless check_date >= start_date and check_date <= end_date
      data+="#{x}:#{y}:"
    }


    @id = data[0..-2] || ''

    @results = @id
    @results = @results.split(':').enum_slice(2).map
    @results = @results.each {|result| result[0] = result[0].to_date}.sort_by{|result| result[0]}
    @results.each{|result| @graph_max = result[1].to_f if result[1].to_f > (@graph_max || 0)}
    @graph_max ||= 0
    render :layout => false
  end

  def internal_consistency_checks
    @patients = CohortTool.internal_consistency_checks(params[:quater])
    @quater = params[:quater]
    render :layout => false
  end

  def records_that_were_updated
    @encounters = CohortTool.records_that_were_updated(params[:quater])
    @quater =params[:quater]
    render :layout => false
  end

end
