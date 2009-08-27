class CohortToolController < ApplicationController

  def menu
   render :layout => false
  end

  def select
    @report_type = params[:report_type]
    if @report_type == "non-eligible_patients_in_cohort"
      @arv_number_start = params[:arv_number_start]
      @arv_number_end = params[:arv_number_end]
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
          redirect_to :action => "non_ligible_patients_in_cohort",:quater => params[:report].gsub("_"," "),
                      :arv_number_start => params[:arv_number_start],:arv_number_end => params[:arv_number_end]
          return
        when "internal_consistency_checks"
          redirect_to :action => "internal_consistency_checks",:quater => params[:report].gsub("_"," ")
          return
        when "summary_of_records_that_were_updated"
          redirect_to :action => "records_that_were_updated",:quater => params[:report].gsub("_"," ")
          return
      end
    end

  end
  
  def arv_number_range
    @report_type = params[:report_type]
  end

  def non_ligible_patients_in_cohort
    session[:list_of_patients] = CohortTool.non_ligible_patients_in_cohort(params[:quater],params[:arv_number_start],params[:arv_number_end])
    quater = params[:quater] + ": (#{patients.length})" rescue  params[:quater]
    redirect_to :action => "list",:quater => quater,:report_type => "Non-ligible patients in cohort"
    return
  end

  def consistency_checks 
    patients = Patient.find(:all,:conditions =>["patient_id IN (?)",params[:id].split(",")])
    quater = params[:quater] + ": (#{patients.length})" rescue  params[:quater]
    session[:list_of_patients] = CohortTool.patients_to_show(patients)
    redirect_to :action => "list",:quater => quater,:report_type => params[:report_type]
    return
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
    @name="CD4_count"
    @pat_name="Latness Dziunde"


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
