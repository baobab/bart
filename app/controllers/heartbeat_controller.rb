class HeartbeatController < ApplicationController
  
  before_filter :authorize, :except => ['update']

  def update
    ip = request.env['REMOTE_ADDR']
		time = Time.now
#		@location = params[:location] || ""
		url = params[:url] || ""
    username = params[:username] rescue nil
    username = User.find(session[:user_id]).username rescue '' unless username
    load_average = `uptime | cut -d ":" -f 5 | cut -d "," -f 1`
    debug_string = ""

    hb_params = params

    hb_params.delete(:url)
    hb_params.delete(:username)
    hb_params.delete(:action)
    hb_params.delete(:controller)
    hb_params[:load_average] = load_average
  
    hb_params.each{|property, value|
      heart_beat_attributes = HeartBeat.new
      heart_beat_attributes.ip = ip
      heart_beat_attributes.time_stamp = time
      heart_beat_attributes.property = "#{property}"
      heart_beat_attributes.value = "#{value}"
      heart_beat_attributes.url = url
      heart_beat_attributes.username = username
      heart_beat_attributes.save!
      debug_string += "#{property}: #{value}\n"
    }
    render :text => time.to_s + "\n" + ip + "\n"  + debug_string 

# TODO stuff this into a db table - probably a flexible table that looks like:
# timestamp|ip|property|value
		 
  end


end
