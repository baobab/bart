class AdminController < ApplicationController

  def alert_wrong_date
    render :layout => false
  end

  def set_new_date
    render :layout => false
  end

  def set_date
    year = params[:post]["new_date(1i)"]
    month = params[:post]["new_date(2i)"]
    day = params[:post]["new_date(3i)"]
    hour = params[:post]["new_date(4i)"]
    min = params[:post]["new_date(5i)"]

    month_and_day = "#{year}-#{month}-#{day}".to_date.strftime("%m%d")
    full_datetime_string = "#{month_and_day}#{hour}#{min}#{year}"

    command = `date #{full_datetime_string}`
    redirect_to(:controller => "user", :action => "login")
  end

end
