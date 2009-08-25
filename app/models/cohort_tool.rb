class CohortTool < OpenMRS
  set_table_name "encounter"

  def self.adherence(quater="Q1 2009")
    date = self.cohort_date(quater)
     
    start_date = (date.to_s + " 00:00:00")
    end_date = date + 3.month - 1.day
    end_date = (end_date.to_s + " 23:59:59")
    encounter_type = EncounterType.find_by_name("Give drugs").id

    encounters = self.find(:all,
                           :joins => "INNER JOIN obs ON obs.encounter_id = encounter.encounter_id AND obs.voided = 0",
                           :conditions => ["encounter_type=? AND encounter_datetime >=? AND encounter_datetime <=?",
                           encounter_type,start_date,end_date],
                           :group => "encounter.patient_id",:order => "encounter_datetime DESC")

    adherence = Hash.new(0)
    puts ">> #{Time.now()}"
    encounters.each{|encounter|
      adh = Patient.find(encounter.patient_id).adherence(encounter.encounter_datetime.to_date) 
      adh = "Not done" if adh.blank?
      #puts "............#{adh}"
      adherence[adh]+=1
    }
    puts ">> #{Time.now()}"
    adherence
  end

  def self.cohort_date(quater)
    q = quater.split(" ").first
    year = quater.split(" ").last.to_i

    case q
      when "Q1"
        return Date.new(year,1,1)
      when "Q2"
        return Date.new(year,4,1)
      when "Q3"
        return Date.new(year,7,1)
      when "Q4"
        return Date.new(year,10,1)
    end
  end

  def self.visits_by_day(quater)
    date = self.cohort_date(quater)
    start_date = (date.to_s + " 00:00:00")
    end_date = date + 3.month - 1.day
    end_date = (end_date.to_s + " 23:59:59")
    encounter_type = EncounterType.find_by_name("Barcode scan").id
    visits_by_day = Hash.new(0)

    encounters = self.find(:all,
                           :joins => "INNER JOIN obs ON obs.encounter_id = encounter.encounter_id AND obs.voided = 0",
                           :conditions => ["encounter_type <> (?) AND encounter_datetime >=? AND encounter_datetime <=?",
                           encounter_type,start_date,end_date],
                           :group => "encounter.patient_id,DATE(encounter_datetime)",:order => "encounter_datetime ASC")

    encounters.each{|encounter|
      visits_by_day[encounter.encounter_datetime.strftime("%d-%b-%Y")]+=1
    }
    visits_by_day
  end


  def self.non_ligible_patients_in_cohort(quater,arv_number_range_start,arv_number_range_end)
    date = self.cohort_date(quater)
    start_date = (date.to_s + " 00:00:00")
    end_date = date + 3.month - 1.day
    end_date = (end_date.to_s + " 23:59:59")
    identifier_type = PatientIdentifierType.find_by_name("Arv national id").id
    patients = Hash.new()

    pats = Patient.find(:all,
                         :joins => "INNER JOIN patient_identifier i on i.patient_id=patient.patient_id
                         INNER JOIN patient_start_dates s ON i.patient_id=s.patient_id",
                         :conditions => ["i.voided=0 and i.identifier_type = ? and s.start_date > ?
                         and s.start_date < ? and char_length(identifier) < ? OR char_length(identifier) > ?
                         OR i.identifier IS NULL",
                         identifier_type,start_date,end_date,arv_number_range_start,arv_number_range_end],
                         :group => "i.patient_id",:order => "char_length(identifier) ASC")
   
    pats.each{|patient|
      patients[patient.id]={"id" =>patient.id,"arv_number" => patient.arv_number,
                           "name" =>patient.name,"national_id" =>patient.national_id,
                           "gender" =>patient.sex,"age" =>patient.age,"birthdate" => patient.birthdate,
                           "start_date" => patient.date_started_art}
    }
   patients


=begin

  <td><%= patient[:id] %></td>
    <td><%= patient[:arv_number] %></td>
    <td><%= patient[:name] %></td>
    <td><%= patient[:national_id] %></td>
    <td><%= patient[:name] %></td>
    <td><%= patient[:gender] %></td>
    <td><%= patient[:age] %> </td>
    <td><%= patient[:birthdate] %> </td>
    <td><%= patient[:start_date].strftime('%Y-%m-%d')%></td>

    SELECT date(s.start_date),p.identifier FROM patient_identifier p inner join patient_start_dates s  on p.patient_id=s.patient_id where p.voided=0 and p.identifier_type = 18 and date(s.start_date) >='2009-01-01' and date(s.start_date) <='2009-03-31' and char_length(identifier) < 61 or char_length(identifier) > 120 group by p.patient_id order by s.patient_id
=end
  end

end
