# This code is temporary for updating the occupation from the patient register
# This was needed because the occupation is not listed on the mastercard
class RetrospectiveOccupation

  def execute
    ask_arv_range  
    find_arv_patients_ids
    find_arv_patients
    update_occupations
  end

  attr_accessor :arv_range, :arv_patient_ids, :arv_patients

  def ask_arv_range(start_number = nil, end_number = nil,arv_prefix = nil)
    unless start_number
      puts "Enter the starting ARV number (as a number)" 
      start_number = STDIN.gets.strip().to_i
    end
    unless end_number  
      puts "Enter the ending ARV number (as a number)"
      end_number = STDIN.gets.strip().to_i    
    end  
   unless arv_prefix  
      puts "Enter the ARV prefix for the healthcenter"
      arv_prefix = STDIN.gets.strip().to_s.upcase
    end  
   @arv_range = (start_number..end_number).map {|n| "#{arv_prefix} #{n}"}  
  end

  def find_arv_patients_ids
    arv_national_id_type = PatientIdentifierType.find_by_name("ARV national id")
    identifiers = PatientIdentifier.find(:all, :conditions => 
      ['identifier_type = ? and identifier IN (?)', arv_national_id_type.id, @arv_range])    
    @arv_patient_ids = identifiers.map(&:patient_id) 
  end
  
  def find_arv_patients
    @arv_patients = Patient.find(:all, :include => [:patient_names, :patient_identifiers],
      :conditions => ['patient.patient_id IN (?)', @arv_patient_ids])
    @arv_patients = @arv_patients.sort{|a,b| a.arv_number <=> b.arv_number}  
  end

  def update_occupations(default = nil)
    @arv_patients.each {|patient| 
    User.current_user = User.find(64)   
   begin
        puts ""
        puts "-----------------------------------------------------------------"
        puts "#{patient.arv_number}: #{patient.first_name} #{patient.last_name}"
        puts "Current occupation: #{patient.occupation}"
        puts "-----------------------------------------------------------------"
        puts "Please type the number of the occupation for this patient:"
        puts "  (1) Farmer"
        puts "  (2) Business"
        puts "  (3) Student"
        puts "  (4) Teacher"
        puts "  (5) Housewife"
        puts "  (6) Health Care Worker"
        puts "  (7) Soldier"
        puts "  (8) Police"
        puts "  (9) Other"
        puts "  (0) Skip"
        ans = default ? default : STDIN.gets.strip().to_i
        case ans 
          when 1
            patient.occupation = "Farmer"
          when 2
            patient.occupation = "Business"
          when 3
            patient.occupation = "Student"
          when 4
            patient.occupation = "Teacher"
          when 5
            patient.occupation = "Housewife"
          when 6
            patient.occupation = "Health Care Worker"
          when 7
            patient.occupation = "Soldier"
          when 8
            patient.occupation = "Police"
          when 9
            patient.occupation = "Other"
        end  
        patient.save! unless ans == 0
      rescue
        puts "You have input an invalid value #{ans}, patient skipped"
      end    
    }
  end

end 
