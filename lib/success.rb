# Adds a convenience method that lets us know the current method's name
class Object
  def this_method
    caller[0]=~/`(.*?)'/
    $1
  end
end

class Success

  @@sent_alert = false

  def self.sent_alert
    @@sent_alert
  end

  def self.sent_alert=(value)
    @@sent_alert=value
  end

  def self.verify
	  return if self.sent_recent_alert?
    self.should_have_a_login_screen
    self.should_have_3_mongrels
    self.should_not_run_hot
    self.should_have_free_memory
    self.should_have_free_disk_space
    self.should_have_more_than_ten_minutes_uptime
    if clinic_is_active?
      self.should_have_recent_encounter
      self.should_have_low_load_average
    end
	end
	
	def self.reset(value = "")
    property = GlobalProperty.find_by_property("last_error_reported")
		property ||= GlobalProperty.new(:property => "last_error_reported")
		property.property_value = value
		property.save!
	end

  def self.sent_recent_alert?(since = 10.minutes.ago)
	  value = GlobalProperty.find_by_property("last_error_reported").property_value rescue nil
	  last_alert = Time.parse(value) unless value.blank?
    last_alert > since
  rescue
    return false
  end

  def self.clinic_is_active?(current_time = Time.now)
    GlobalProperty.find_by_property("clinic_breaks").property_value.split(/, */).each{|break_range|
      break_start, break_finish = break_range.split(/- */)
      return false if current_time.between?(Time.parse(break_start), Time.parse(break_finish))
    }

    GlobalProperty.find_by_property("clinic_hours").property_value.split(/, */).each{|clinic_hours_range|
      clinic_hours_start, clinic_hours_finish = clinic_hours_range.split(/- */)
      return false unless current_time.between?(Time.parse(clinic_hours_start), Time.parse(clinic_hours_finish))
    }
    return true
    rescue => exception
      return true
  end

  def self.clinic_hours=(value = "7:30am-3:45pm")
    Success.set_global_property("clinic_hours",value)
  end

  def self.clinic_breaks=(value = "12:30pm-1:00pm,1:00pm-1:15pm")
    Success.set_global_property("clinic_breaks",value)
  end

  def self.smtp_server=(value)
    Success.set_global_property("smtp_server",value)
  end

  def self.set_global_property(property,value)
    property = GlobalProperty.find_or_create_by_property(property)
#		property ||= GlobalProperty.new(:property => property)
		property.property_value = value
		property.save!
  end
	
protected

  def self.should_have_recent_encounter(since = 5.minutes.ago)
    puts this_method.capitalize.gsub(/_/, " ")
  	last_encounter_time = Encounter.find(:first, :order => 'encounter_id DESC').date_created
	  self.alert "Last encounter occurred > five minutes ago (#{last_encounter_time.hour}:#{last_encounter_time.min})" if last_encounter_time < since
	end

  def self.should_have_a_login_screen
    puts this_method.capitalize.gsub(/_/, " ")
    login_screen = `lynx --dump localhost`
    #login_screen = shell("lynx --dump localhost")
    self.alert "No login screen available:\n #{login_screen}" unless login_screen.match(/Loading User Login/)
	end

  def self.should_have_3_mongrels
    puts this_method.capitalize.gsub(/_/, " ")
    self.alert "3 mongrels are not running:\npgrep mongrel\n#{`pgrep mongrel`}" unless `pgrep mongrel`.split(/\n/).length == 3 rescue false
  end

  def self.should_not_run_hot
    puts this_method.capitalize.gsub(/_/, " ")
    current_temp = `cat /proc/acpi/thermal_zone/*/temperature | head -1`.match(/\d+/).to_s.to_i rescue nil
    self.alert "Machine is running hot: #{current_temp}" if current_temp.blank? || current_temp > 55
  end

  def self.should_have_free_memory
    puts this_method.capitalize.gsub(/_/, " ")
    mem_free = `cat /proc/meminfo | grep MemFree`
    mem_free_amount = mem_free.match(/\d+/)[0].to_i
    alert "Machine is running out of memory: #{mem_free_amount}" if mem_free_amount < (128 * 1024) # 128 MB
  rescue
    alert "Could not check the free memory"      
  end
  
  def self.should_have_free_disk_space
    puts this_method.capitalize.gsub(/_/, " ")
    disk_free = `df /var/www | grep / `
    disk_free_amount = disk_free.split[3].to_f
    alert "Machine is running out of disk space: #{disk_free_amount}KB free" if disk_free_amount < 1048576 # 1 Gig
  rescue
    alert "Could not check the free disk space"        
  end

  def self.should_have_more_than_ten_minutes_uptime
    puts this_method.capitalize.gsub(/_/, " ")
    uptime = `cat /proc/uptime`
    uptime_seconds = uptime.split(/ +/)[0].to_f
    alert "System was rebooted at #{Time.now - uptime_seconds}" if uptime_seconds/60 < 10
  rescue 
    alert "Could not check uptime"
  end

  def self.should_have_low_load_average
    puts this_method.capitalize.gsub(/_/, " ")
    load_average = `cat /proc/loadavg`
    fifteen_minute_load_average = load_average.split(/ +/)[2].to_f
    alert "System has a high load average over the past 15 minutes: #{fifteen_minute_load_average}" if fifteen_minute_load_average > 2
  rescue 
    alert "Could not check load average"
  end

  def self.get_recent_log
    `tail /var/www/bart/`
  end

private 

  def self.shell(string)
    return `#{string}`
  end

  def self.current_location
    Location.find(GlobalProperty.find_by_property("current_health_center_id").property_value).name rescue "Unknown location"
	end
	
	def self.current_ip_address
    # This code does not make an actual connection, but sets up
    # a UDP connection and examines the route to figure out the IP
    require 'socket'
 
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily  
   
    UDPSocket.open do |s|  
      s.connect '64.233.187.99', 1 
      s.addr.last  
    end  
  ensure  
     Socket.do_not_reverse_lookup = orig  
  end  

  def self.alert(subject)
    @@sent_alert = true
    require 'smtp_tls'

# Also log to rails log
    puts subject
    RAILS_DEFAULT_LOGGER.warn subject

    username = GlobalProperty.find_by_property("smtp_username").property_value rescue ""
    password = GlobalProperty.find_by_property("smtp_password").property_value rescue ""

		self.reset(DateTime.now.to_default_s)
	  body = "#{subject} @ #{self.current_location} (#{self.current_ip_address}) at #{Time.now}"
    sender = "success@baobabhealth.org"
    receivers = {"malawihackers@baobabhealth.org" => "Support Team", "ga744ktwed@twittermail.com" => "BaobabHealthTweet"}
    #Support Team <#{receiver}>, BaobabHealthTweet <ga744ktwed@twittermail.com>
    to_line = receivers.collect{|key,value| value + " <#{key}>"}.join(", ")

    email_message = <<END_OF_MESSAGE
From: Success <#{sender}>
To: #{to_line}
Subject: #{subject}

#{body}
END_OF_MESSAGE

    smtp_server = self.global_property("smtp_server") || "localhost"

    Net::SMTP.start('smtp.gmail.com', 587, 'localhost', username, password, 'plain' ) do |smtp|
      smtp.send_message email_message, sender, receivers.keys
    end

  end

  def self.global_property(property)
    value = GlobalProperty.find_by_property(property)
    value ? value.property_value : nil
  end

end
