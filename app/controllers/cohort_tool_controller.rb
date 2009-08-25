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
    if params[:report]
      case  params[:report_type]
        when "visits_by_day"
          redirect_to :action => "graph",:name => params[:report],
                      :pat_name => "Visits by day",:quater => params[:report].gsub("_"," ")
          return
        when "non-eligible_patients_in_cohort"
          redirect_to :action => "list",:quater => params[:report].gsub("_"," "),
                      :arv_number_start => params[:arv_number_start],:arv_number_end => params[:arv_number_end]
          return
      end
    end

  end
  
  def arv_number_range
    @report_type = params[:report_type]
  end

  def list
    @patients = CohortTool.non_ligible_patients_in_cohort(params[:quater],params[:arv_number_start],params[:arv_number_end])
    @quater = params[:quater] + ": (#{@patients.length})" rescue  params[:quater]
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

end
