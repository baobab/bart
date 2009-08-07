class AdminController < ApplicationController

  def alert_wrong_date
    last_encounter = params[:last_encounter]
    @encounter_name = last_encounter.keys.to_s
    @last_recorded_date = last_encounter[@encounter_name]["Date"].to_date
    @user = last_encounter[@encounter_name]["User"]
    @encounter_time =  last_encounter[@encounter_name]["Date"].to_time.strftime("%H:%M")
    render :layout => false
  end

  def set_new_date
  end

  def set_date
    year = params[:post]["new_date(1i)"]
    month = params[:post]["new_date(2i)"]
    day = params[:post]["new_date(3i)"]
    hour = params[:post]["new_date(4i)"]
    min = params[:post]["new_date(5i)"]

    set_datetime_string = "#{year}-#{month}-#{day} #{hour}:#{min}".to_time

    if Date.today < Encounter.last.encounter_datetime.to_date
      `date #{set_datetime_string.strftime('%d%m%H%M%Y')}`
    end
    redirect_to(:controller => "user", :action => "activities")
  end

end
