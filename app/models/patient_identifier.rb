require "composite_primary_keys"
class PatientIdentifier < OpenMRS
  set_table_name "patient_identifier"
  belongs_to :type, :class_name => "PatientIdentifierType", :foreign_key => :identifier_type
  belongs_to :patient, :foreign_key => :patient_id
  belongs_to :user, :foreign_key => :user_id
  belongs_to :location, :foreign_key => :location_id
  set_primary_keys :patient_id, :identifier, :identifier_type

  def all_identifiers
    PatientIdentifier.find_all_by_patient_id(self.patient_id)
  end

  def self.create(patient_id, identifier, identifier_type_name)    
    type_id = PatientIdentifierType.find_by_name(identifier_type_name).id rescue nil
    return false if type_id.blank? || patient_id.blank? || identifier.blank?
    patient_identifier = self.new()
    patient_identifier.patient_id = patient_id
    patient_identifier.identifier = identifier.to_s.gsub("identifier","")
    patient_identifier.identifier_type = type_id
    patient_identifier.save
  end

	# Update an identifier with the one given
	# If new identifier is different from any of the current ones, current one is voided and new identifier created
	# If new identifier is same as an exisiting but voided one, the existing one is un-voided
	# If new identifier is same as an exisiting and unvoided one, all other identifiers of that type will be voided
  def self.update(patient_id, identifier, identifier_type, reason)    
    current_numbers = PatientIdentifier.find_all_by_patient_id_and_identifier_type(patient_id, identifier_type)
    number_found = false
    current_numbers.each{|current|
      if current.identifier == identifier 
        if current.voided?
          current.voided = false
          current.void_reason = nil
          current.save!
        end
        number_found = true
      else
        current.void!(reason)
        current.save!
      end
    }

    unless number_found
      new_obj = PatientIdentifier.new
      new_obj.identifier = identifier
      new_obj.identifier_type = identifier_type
      new_obj.patient_id = patient_id
      new_obj.save!
   end
  end  

  def self.find_all_by_identifier_type_name(type_name)
    PatientIdentifier.find_all_by_identifier_type(PatientIdentifierType.find_by_name(type_name).patient_identifier_type_id)
  end 

  def to_s
    "#{self.type.name}: #{self.identifier}"
  end

  def self.calculate_checkdigit(number)
    # This is Luhn's algorithm for checksums
    # http://en.wikipedia.org/wiki/Luhn_algorithm
    # Same algorithm used by PIH (except they allow characters)
    number = number.to_s
    number = number.split(//).collect { |digit| digit.to_i }
    parity = number.length % 2

    sum = 0
    number.each_with_index do |digit,index|
      digit = digit * 2 if index%2==parity
      digit = digit - 9 if digit > 9
      sum = sum + digit
    end

    checkdigit = 0
    checkdigit = checkdigit +1 while ((sum+(checkdigit))%10)!=0
    return checkdigit
  end

  def self.get_next_patient_identifier(identifier_type = "National id")
    case identifier_type
    when "National id"
      Patient.next_national_id
    when "Filing number", "Archived filing number"
      get_next_filing_number(identifier_type)
    when "Arv national id"
      get_next_arv_national_id
    end
  end

  def self.get_next_arv_national_id
    conditions = ["identifier like ?", "#{Location.current_arv_code}%"]
    last = get_last_filing_number("Arv national id", conditions)
    if last
      last.succ
    else
      Location.current_arv_code + " 1"
    end
  end

  def self.filing_number_prefix(type_name)
    property = GlobalProperty.find_by_property('filing_number_prefix')
    raise "No filing number prefix configured" unless property
    prefix = property.property_value
    if type_name =~ /archived/i
      prefix.split(',').last
    else
      prefix.split(',').first
    end
  end

  def self.get_next_filing_number(type_name = 'Filing number')
    prefix = filing_number_prefix(type_name)
    conditions = ["identifier like ?", "#{prefix}%"]
    last = get_last_filing_number(type_name, conditions)
    if last
      last.succ
    else
      prefix + "00001"
    end
  end

  def self.get_last_filing_number(type_name, conditions = {})
    type = PatientIdentifierType.find_by_name(type_name)
    id = type.patient_identifiers.find(:first, :conditions => conditions, :order => "identifier DESC")
    id ? id.identifier : nil
  end

  def self.duplicates_by_type(identifier_type)
    return if identifier_type.class != PatientIdentifierType
    sql_text = "SELECT identifier, count(patient_id) AS patient_count FROM patient_identifier"
    sql_text += " WHERE identifier_type = #{identifier_type.id} AND voided = 0"
    sql_text += " GROUP BY identifier HAVING patient_count > 1"
    self.find_by_sql sql_text
  end
 
end

### Original SQL Definition for patient_identifier #### 
#   `patient_id` int(11) NOT NULL default '0',
#   `identifier` varchar(50) NOT NULL default '',
#   `identifier_type` int(11) NOT NULL default '0',
#   `preferred` tinyint(4) NOT NULL default '0',
#   `location_id` int(11) NOT NULL default '0',
#   `creator` int(11) NOT NULL default '0',
#   `date_created` datetime NOT NULL default '0000-00-00 00:00:00',
#   `voided` tinyint(1) NOT NULL default '0',
#   `voided_by` int(11) default NULL,
#   `date_voided` datetime default NULL,
#   `void_reason` varchar(255) default NULL,
#   PRIMARY KEY  (`patient_id`,`identifier`,`identifier_type`),
#   KEY `defines_identifier_type` (`identifier_type`),
#   KEY `identifier_creator` (`creator`),
#   KEY `identifier_voider` (`voided_by`),
#   KEY `identifier_location` (`location_id`),
#   KEY `identifier_name` (`identifier`),
#   CONSTRAINT `defines_identifier_type` FOREIGN KEY (`identifier_type`) REFERENCES `patient_identifier_type` (`patient_identifier_type_id`),
#   CONSTRAINT `identifier_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `identifier_voider` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`),
#   CONSTRAINT `identifies_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`),
#   CONSTRAINT `patient_identifier_ibfk_2` FOREIGN KEY (`location_id`) REFERENCES `location` (`location_id`)
