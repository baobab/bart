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

  def self.next_available_arv_id
    return self.get_next_patient_identifier(identifier_type = "Arv national id")
    current_arv_code = Location.current_arv_code
    current_arv_number_identifiers = PatientIdentifier.find_all_by_identifier_type_name("Arv national id")
    assigned_arv_ids = current_arv_number_identifiers.collect{|identifier|
      $1.to_i if identifier.identifier.match(/#{current_arv_code} *(\d+)/)
    }.compact unless current_arv_number_identifiers.nil?
    next_available_number = nil
    if assigned_arv_ids.empty?
      next_available_number = 1
    else
      # Check for unused ARV idsV
      # Suggest the next arv_id based on unused ARV ids that are within 10 of the current_highest arv id. This makes sure that we don't get holes unless we really want them and also means that our suggestions aren't broken by holes
      #array_of_unused_arv_ids = (1..highest_arv_id).to_a - assigned_arv_ids
      highest_arv_id = assigned_arv_ids.sort.last
      hole_range = 10

      array_of_unused_arv_ids = (highest_arv_id-hole_range..highest_arv_id).to_a - assigned_arv_ids
      if array_of_unused_arv_ids.empty?
        next_available_number = highest_arv_id + 1
      else
        next_available_number = array_of_unused_arv_ids.first
      end
    end
    return "#{current_arv_code} #{next_available_number}"
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
    return Patient.next_national_id if identifier_type == "National id"
    current_identifiers = PatientIdentifier.find_all_by_identifier_type_name(identifier_type).collect{|identifier|identifier.identifier unless identifier.voided}
    prefix = Location.current_arv_code + " " if identifier_type == "Arv national id"
    filing_number_prefix = GlobalProperty.find_by_property("filing_number_prefix").property_value rescue "FN101,FN102" if identifier_type.match(/filing/i)
    prefix = filing_number_prefix.split(",")[0][0..3] if identifier_type.match(/filing/i)
    return if prefix.blank?

    len_of_identifier = 0 if identifier_type == "Arv national id"
    len_of_identifier = (filing_number_prefix.split(",")[0][-1..-1] + "00000").to_i if identifier_type == "Filing number"
    len_of_identifier = (filing_number_prefix.split(",")[1][-1..-1] + "00000").to_i if identifier_type == "Archived filing number"

    possible_identifiers_range = GlobalProperty.find_by_property("arv_number_range").property_value.to_i rescue 100000 if identifier_type=="Arv national id"
    possible_identifiers_range = GlobalProperty.find_by_property("filing_number_range").property_value.to_i rescue 5000  if identifier_type =="Filing number"
    possible_identifiers_range = GlobalProperty.find_by_property("dormant_filing_number_range").property_value.to_i rescue 12000  if identifier_type =="Archived filing number"

    possible_identifiers = Array.new(possible_identifiers_range){|i|prefix + (len_of_identifier + i +1).to_s}
    next_identifier = ((possible_identifiers)-(current_identifiers.compact.uniq)).first
    return next_identifier unless next_identifier.blank?
    possible_identifiers.last
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
