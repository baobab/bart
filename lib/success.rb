class Success

  def self.verify
	  return unless self.active?
    self.should_have_encounter_within_the_last_five_minutes	  
    self.should_have_a_login_screen
    self.should_have_3_mongrels
    self.should_not_run_hot
	end
	
	def self.reset(value = "")
    property = GlobalProperty.find_by_property("last_error_reported")
		property ||= GlobalProperty.new(:property => "last_error_reported")
		property.property_value = value
		property.save!
	end

  def self.active?
    return false if last_alert && last_alert.to_time > 10.minutes.ago
    start_time = GlobalProperty.find_by_property("success_start_hour").property_value.to_i rescue nil
    end_time = GlobalProperty.find_by_property("success_end_hour").property_value.to_i rescue nil
		return start_time.blank? || end_time.blank? || (Time.now.hour >= start_time && Time.now.hour < end_time)
  end

	def self.start_hour=(value = "")
    property = GlobalProperty.find_by_property("success_start_hour")
		property ||= GlobalProperty.new(:property => "success_start_hour")
		property.property_value = value
		property.save!
	end
	
	def self.end_hour=(value = "")
    property = GlobalProperty.find_by_property("success_end_hour")
		property ||= GlobalProperty.new(:property => "success_end_hour")
		property.property_value = value
		property.save!
	end
	
protected

  def self.should_have_encounter_within_the_last_five_minutes
  	last_encounter_time = Encounter.find(:first, :order => 'encounter_id DESC').date_created
	  alert "Last encounter occurred more than five minutes ago (#{last_encounter_time})" if last_encounter_time < 5.minutes.ago
	end

  def self.should_have_a_login_screen
    login_screen = `lynx --dump localhost`
    alert "No login screen available:\n #{login_screen}" unless login_screen.match(/Loading User Login/)
	end

  def self.should_have_3_mongrels
    alert "3 mongrels are not running:\npgrep mongrel\n#{`pgrep mongrel`}" unless `pgrep mongrel`.split(/\n/).length == 3 rescue false
  end

  def self.should_not_run_hot
    current_temp = `cat /proc/acpi/thermal_zone/THRM/temperature`.match(/\d+/).to_s.to_i rescue nil
    alert "Machine is running hot: #{current_temp}" if current_temp.blank? || current_temp > 55
  end

private 

  def self.current_location
    Location.find(GlobalProperty.find_by_property("current_health_center_id").property_value).name rescue "Unknown location"
	end
	
	def self.current_address
  	`ifconfig | grep "192"`.match(/192\.168\.\d+\.\d+/)
	end

	def self.last_alert
	  value = GlobalProperty.find_by_property("last_error_reported").property_value rescue nil
	  return Time.parse(value) unless value.blank?
		return nil
	end

  def self.alert(message)
	  message = "#{self.current_location} (#{self.current_address}) was not successful on #{Time.now} with message:\n#{message}"
    puts message
    `echo "#{message}" | mail -s "Success failure" malawihackers@baobabhealth.org`
		self.reset(DateTime.now.to_default_s)
	end

end
