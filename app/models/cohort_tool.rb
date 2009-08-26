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
    encounter_ids = Array.new()
    encounter_ids << EncounterType.find_by_name("Barcode scan").id
    encounter_ids << EncounterType.find_by_name("TB Reception").id
    encounter_ids << EncounterType.find_by_name("General Reception").id
    encounter_ids << EncounterType.find_by_name("Move file from dormant to active").id
    encounter_ids << EncounterType.find_by_name("Update outcome").id

    visits_by_day = Hash.new(0)

    encounters = self.find(:all,
                           :joins => "INNER JOIN obs ON obs.encounter_id = encounter.encounter_id AND obs.voided = 0",
                           :conditions => ["encounter_type NOT IN (?) AND encounter_datetime >=? AND encounter_datetime <=?",
                           encounter_ids,start_date,end_date],
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

    pats = Patient.find(:all,
                         :joins => "INNER JOIN patient_identifier i on i.patient_id=patient.patient_id
                         INNER JOIN patient_start_dates s ON i.patient_id=s.patient_id",
                         :conditions => ["i.voided=0 and i.identifier_type = ? and s.start_date > ?
                         and s.start_date < ? and char_length(identifier) < ? OR char_length(identifier) > ?
                         OR i.identifier IS NULL",
                         identifier_type,start_date,end_date,arv_number_range_start,arv_number_range_end],
                         :group => "i.patient_id",:order => "char_length(identifier) ASC")
   
   patients = self.patients_to_show(pats)


=begin
    SELECT date(s.start_date),p.identifier FROM patient_identifier p inner join patient_start_dates s  on p.patient_id=s.patient_id where p.voided=0 and p.identifier_type = 18 and date(s.start_date) >='2009-01-01' and date(s.start_date) <='2009-03-31' and char_length(identifier) < 61 or char_length(identifier) > 120 group by p.patient_id order by s.patient_id
=end
  end

  def self.patients_to_show(pats)
    patients = Hash.new()
    pats.each{|patient|
      patients[patient.id]={"id" =>patient.id,"arv_number" => patient.arv_number,
                           "name" =>patient.name,"national_id" =>patient.national_id,
                           "gender" =>patient.sex,"age" =>patient.age,"birthdate" => patient.birthdate,
                           "start_date" => patient.date_started_art}
    }
   patients
  end

  def self.internal_consistency_checks(quater)
    date = self.cohort_date(quater)
    start_date = (date.to_s + " 00:00:00")
    end_date = date + 3.month - 1.day
    end_date = (end_date.to_s + " 23:59:59")
    patients = Hash.new()

    female_names=''
    male_names=''
   
    #possible female/male names
    ["female","male"].each{|gender|
      File.open(File.join(RAILS_ROOT, "public/list_of_possible_#{gender}_names.csv"), File::RDONLY).readlines[1..-1].each{|line|
        name = line.chomp.split(",").collect{|text|text.gsub(/"/,"")} 
        if gender == "male"      
          male_names+=" OR n.given_name = '#{name}'" unless male_names.blank?
          male_names+="n.given_name = '#{name}'" if male_names.blank?
        else
          female_names+=" OR n.given_name = '#{name}'" unless female_names.blank?
          female_names+="n.given_name = '#{name}'" if female_names.blank?
        end
      }
    }
    
    ["female","male"].each{|gender|
      case gender 
        when "female"
          patients[gender] = self.patients_with_possible_wrong_sex(male_names,start_date,end_date,"Female")
        when "male"
          patients[gender] = self.patients_with_possible_wrong_sex(female_names,start_date,end_date,"Male")
        end
    }
    
    patients["wrong_start_dates"] = self.patients_with_start_dates_less_than_first_give_drug_date(start_date,end_date)

    patients["pregnant_males"] = self.male_patients_with_pregnant_obs(start_date,end_date)

    patients
  end

  def self.patients_with_possible_wrong_sex(additional_sql,start_date,end_date,sex)
    Patient.find(:all,
                 :joins => "INNER JOIN patient_start_dates s ON patient.patient_id=s.patient_id
                 INNER JOIN obs ON obs.patient_id=patient.patient_id
                 INNER JOIN patient_name n ON patient.patient_id=n.patient_id",
                 :conditions => ["n.voided=0 AND obs.voided=0 and s.start_date > ?
                 and s.start_date < ? AND patient.gender=? AND (#{additional_sql})",
                 start_date,end_date,sex],:group => "patient.patient_id")
  end

  def self.patients_with_start_dates_less_than_first_give_drug_date(start_date,end_date)
    encounter_type = EncounterType.find_by_name("Give drugs").id
    Patient.find(:all,
                 :joins => "INNER JOIN patient_start_dates s ON patient.patient_id=s.patient_id
                 INNER JOIN obs ON obs.patient_id=patient.patient_id
                 INNER JOIN encounter e ON obs.encounter_id=e.encounter_id",
                 :conditions => ["obs.voided=0 and s.start_date > ?
                 and s.start_date < ? AND e.encounter_type=? AND (Date(s.start_date) > Date(e.encounter_datetime))",
                 start_date,end_date,encounter_type],
                 :group => "e.patient_id",:order =>"e.encounter_datetime ASC")
  end

  def self.male_patients_with_pregnant_obs(start_date,end_date)
    concept_id = Concept.find_by_name("Pregnant").id
    Patient.find(:all,
                 :joins => "INNER JOIN obs ON patient.patient_id=obs.patient_id
                 INNER JOIN patient_start_dates s ON patient.patient_id=s.patient_id",
                 :conditions => ["obs.voided=0 and s.start_date > ?
                 and s.start_date < ? AND obs.concept_id=? AND patient.gender='Male'",
                 start_date,end_date,concept_id],
                 :group => "obs.patient_id",:order =>"patient.patient_id ASC")
  end

end
