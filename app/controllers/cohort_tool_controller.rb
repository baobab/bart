class CohortToolController < ApplicationController

  def menu
   render :layout => false
  end

  def select
    @report_type = params[:report_type]
    if @report_type == "inclusive_exclusive_report"
      @arv_number_start = params[:arv_number_start]
      @arv_number_end = params[:arv_number_end]
      @arv_select_type = params[:arv_select_type]
    end
  end

  def reports
    session[:list_of_patients] = nil
    if params[:report]
      case  params[:report_type]
        when "visits_by_day"
          redirect_to :action => "graph",:name => params[:report],
                      :pat_name => "Visits by day",:quater => params[:report].gsub("_"," ")
          return
        when "non-eligible_patients_in_cohort"
          date = Report.cohort_date_range(params[:report])
          redirect_to :controller =>"reports", :action => "cohort_debugger",
                      :start_date =>date.first.to_s ,:end_date =>date.last.to_s,
                      :id => "start_reason_other",:report_type =>"Non-eligible patients in: #{params[:report]}"
          return
        when "inclusive_exclusive_report"
          redirect_to :action => "inclusive_exclusive_report",:quater => params[:report].gsub("_"," "),
                      :arv_number_start => params[:arv_number_start],:arv_number_end => params[:arv_number_end],
                      :arv_select_type => params[:arv_select_type]
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
          redirect_to :action => "patients_with_multiple_start_reasons",:quater => params[:report].gsub("_"," ")
          return
      end
    end

  end
  
  def patients_with_multiple_start_reasons
    (@start_date, @end_date) = Report.cohort_date_range(params[:quater])
    cohort = Reports::CohortByRegistrationDate.new(@start_date,@end_date)
    @patients = cohort.patients_with_multiple_start_reasons
    @quater = params[:quater] + ": (#{@patients.length})" rescue  params[:quater]
    @report_type = "Patients with multiple start reasons"
    render :layout => false
  end

  def arv_number_range
    @report_type = params[:report_type]
  end

  def inclusive_exclusive_report
    session[:list_of_patients] = CohortTool.inclusive_exclusive_report(params[:quater],params[:arv_number_start],params[:arv_number_end],params[:arv_select_type])
    quater = params[:quater] + ": (#{session[:list_of_patients].length})" rescue  params[:quater]
    if params[:arv_select_type] =="Include"
      type = "Patients with arv numbers </br>within the range of #{params[:arv_number_start]} to #{params[:arv_number_end]}"
    else  
      type = "Patients with arv numbers </br>out-side the range of #{params[:arv_number_start]} to #{params[:arv_number_end]}"
    end  
    redirect_to :action => "list",:quater => quater,:report_type => type
    return
  end

  def patients_with_adherence_greater_than_hundred
    session[:list_of_patients] = nil
    @patients = CohortTool.adherence_over_hundred(params[:quater])
    @quater = params[:quater] + ": (#{@patients.length})" rescue  params[:quater]
    @report_type = "Patient with adherence greater than 100"
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
    @report_type = "Adherence Histogram for all patients"

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
    @quater = params[:quater] 
    @report_type = params[:report_type]
    render :layout => false
  end

  def graph
    encounters = CohortTool.visits_by_day(params[:quater])
    data = ""
    encounters.each{|x,y|data+="#{x}:#{y}:"}
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
