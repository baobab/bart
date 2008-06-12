class HeartbeatController < ApplicationController

  def update
    @ip = request.env['REMOTE_ADDR']
		@time = Time.now
#		@location = params[:location] || ""
		@url = params[:url] || ""
		@username = User.find(session[:user_id]).username
#    @load_average = `uptime | cut -d ":" -f 5 | cut -d "," -f 1`
    @heart_beat_attributes = HeartBeat.new
    debug_string = ""
    #render:text => params and return
  
    if request.get?
    params.each{|property, value|
      @heart_beat_attributes.ip = @ip
      @heart_beat_attributes.time_stamp = @time
      @heart_beat_attributes.property = "#{property}"
      @heart_beat_attributes.value = "#{value}"
      @heart_beat_attributes.url = @url
      @heart_beat_attributes.username = @username
      render:text => @heart_beat_attributes.to_yaml and return
      @heart_beat_attributes.save!
      debug_string += "#{property}: #{value}\n"
    }
      render :text => @time.to_s + "\n" + @ip + "\n"  + debug_string 
   end

    #render :text => @time.to_s + "\n" + @ip + "\n"  + debug_string
# TODO stuff this into a db table - probably a flexible table that looks like:
# timestamp|ip|property|value
		 
  end


end
