
class Success

  def self.verify
	  return if self.sent_recent_alert?
    self.should_have_a_login_screen
    self.should_have_3_mongrels
    self.should_not_run_hot
    if clinic_is_active?
      self.should_have_encounter_within_the_last_five_minutes	  
    end
	end
	
	def self.reset(value = "")
    property = GlobalProperty.find_by_property("last_error_reported")
		property ||= GlobalProperty.new(:property => "last_error_reported")
		property.property_value = value
		property.save!
	end

  def self.sent_recent_alert?
    last_alert.to_time < 10.minutes.ago 
    rescue
      return false
  end

  def self.clinic_is_active?
    GlobalProperty.find_by_property("clinic_breaks").property_value.split(/, */).each{|break_range|
      break_start, break_finish = break_range.split(/- */)
      return false if Time.now.between?(break_start, break_finish)
    }

    GlobalProperty.find_by_property("clinic_hours").property_value.split(/, */).each{|clinic_hours_range|
      clinic_hours_start, clinic_hours_finish = clinic_hours_range.split(/- */)
      return false unless Time.now.between?(clinic_hours_start, clinic_hours_finish)
    }
    return true
    rescue 
      return true
  end

  def self.clinic_hours=(value = "7:30am-3:45pm")
    Success.set_global_property("clinic_hours",value)
  end

  def self.clinic_breaks=(value = "12:30pm-1:00pm,1:00pm-1:15pm")
    Success.set_global_property("clinic_breaks",value)
  end

  def self.set_global_property(property,value)
    property = GlobalProperty.find_by_property(property)
		property ||= GlobalProperty.new(:property => property)
		property.property_value = value
		property.save!
  end
	
protected

  def self.should_have_encounter_within_the_last_five_minutes
  	last_encounter_time = Encounter.find(:first, :order => 'encounter_id DESC').date_created
	  self.alert "Last encounter occurred more than five minutes ago (#{last_encounter_time})" if last_encounter_time < 5.minutes.ago
	end

  def self.should_have_a_login_screen
    login_screen = `lynx --dump localhost`
    self.alert "No login screen available:\n #{login_screen}" unless login_screen.match(/Loading User Login/)
	end

  def self.should_have_3_mongrels
    self.alert "3 mongrels are not running:\npgrep mongrel\n#{`pgrep mongrel`}" unless `pgrep mongrel`.split(/\n/).length == 3 rescue false
  end

  def self.should_not_run_hot
    current_temp = `cat /proc/acpi/thermal_zone/THRM/temperature`.match(/\d+/).to_s.to_i rescue nil
    self.alert "Machine is running hot: #{current_temp}" if current_temp.blank? || current_temp > 55
  end

private 

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

	end

	def self.last_alert
	  value = GlobalProperty.find_by_property("last_error_reported").property_value rescue nil
	  return Time.parse(value) unless value.blank?
		return nil
	end

  def self.alert(subject)
    require 'net/smtp'
		self.reset(DateTime.now.to_default_s)
	  body = "#{self.current_location} (#{self.current_ip_address}) was not successful at #{Time.now} with message:\n#{message}"
    sender = "success@baobabhealth.org"
    receiver = "malawihackers@baobabhealth.org"

    email_message = <<END_OF_MESSAGE
From: Success <#{sender}>
To: Support Team <#{to}>
Subject: #{subject}
#{message}
END_OF_MESSAGE

Net::SMTP.start('your.smtp.server', 25) do |smtp|
  smtp.send_message email_message, sender, receiver
end


end
