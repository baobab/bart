class OutpatientReportController < ApplicationController
#  include PdfHelper
  def menu
  end

  def diagnosis_report
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'menu'
      return
    end
   
    start_date = (@start_date.to_s + " 00:00:00")
    end_date = (@end_date.to_s + " 23:59:59") 
    diagnosis_ids = []
    diagnosis_ids << Concept.find_by_name('Primary diagnosis').id
    diagnosis_ids << Concept.find_by_name('Secondary diagnosis').id
    outpatient_encounter_type = EncounterType.find_by_name('Outpatient diagnosis')
    selected_groups = []
    params[:age_groups].split(',').each{|selected_group|
      selected_groups << "'#{selected_group}'"
    }
    
    diagnosis = Concept.find_by_sql("SELECT `concept`.*,age_group(p.birthdate,
       Date(encounter_datetime),Date(p.date_created),
       p.birthdate_estimated) as age_groups FROM `concept` 
       INNER JOIN obs ON obs.value_coded = concept.concept_id
       INNER JOIN encounter e ON e.encounter_id = obs.encounter_id 
       INNER JOIN patient p ON p.patient_id=e.patient_id
       WHERE (e.encounter_type=#{outpatient_encounter_type.id} 
       AND e.encounter_datetime >= '#{start_date}'
       AND e.encounter_datetime <= '#{end_date}' AND obs.voided=0 
       AND obs.concept_id IN (#{diagnosis_ids.join(',')})) 
       HAVING age_groups IN (#{selected_groups.join(',')})
       ORDER BY concept.name ASC")

    @diagnosis = Hash.new(0)
    diagnosis.each{|diagno|
      next if diagno.name == "Not applicable"
      @diagnosis[diagno.name]+=1
    }
    @age_groups = []
    count = 0
    params[:age_groups].split(',').each{|group|
     @age_groups << "(#{count+=1}) #{group}  "
    }
    @age_groups = @age_groups.to_s
    render(:layout => "layouts/menu")
  end

  def disaggregated_diagnosis
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'menu'
      return
    end
   

    start_date = (@start_date.to_s + " 00:00:00")
    end_date = (@end_date.to_s + " 23:59:59") 
    outpatient_encounter_type = EncounterType.find_by_name('Outpatient diagnosis')
    diagnosis_ids = []
    diagnosis_ids << Concept.find_by_name('Primary diagnosis').id
    diagnosis_ids << Concept.find_by_name('Secondary diagnosis').id

    patient_birtdates_diagnosis = Observation.find(:all,
      :joins =>"INNER JOIN concept c ON obs.value_coded = c.concept_id
      INNER JOIN encounter e ON e.encounter_id = obs.encounter_id
      INNER JOIN patient p ON p.patient_id=obs.patient_id",
      :conditions =>["e.encounter_type=? AND e.encounter_datetime >= ?
      AND e.encounter_datetime <= ? AND obs.voided=0 AND obs.concept_id IN (?)",
      outpatient_encounter_type.id,start_date,end_date,diagnosis_ids],
      :order => "c.name ASC",
      :select => "p.birthdate AS birtdate,c.name AS name,obs.obs_datetime AS obs_date ,p.gender AS gender,p.date_created AS patient_date_created,p.birthdate_estimated AS birthdate_estimated").collect{|value|[value.birtdate,value.name,value.obs_date,value.gender,value.patient_date_created,value.birthdate_estimated]}


    @diagnosis=Hash.new()
    patient_birtdates_diagnosis.each{|patient_birtdate_diagnosis|
      birtdate,diagnosis,obs_date,gender,patient_date_created,birtdate_estimated = patient_birtdate_diagnosis.map {|values|values}
      next if diagnosis == "Not applicable"
      next if birtdate.blank?
      age_group = age(birtdate.to_date,obs_date.to_date,patient_date_created,birtdate_estimated)
      @diagnosis[diagnosis] = {"< 6 MONTHS:M" => 0,"< 6 MONTHS:F" =>0,">14:M" => 0,
                              "6 MONTHS TO < 5:F" => 0,"6 MONTHS TO < 5:M" =>0,
                              ">14:F" => 0,"5-14:F" => 0,"5-14:M" =>0} if @diagnosis[diagnosis].blank?

      if age_group == "< 6 Months" and gender == "Female"
         @diagnosis[diagnosis]['< 6 MONTHS:F']+=1
      elsif age_group == "< 6 Months" and gender == "Male"
         @diagnosis[diagnosis]['< 6 MONTHS:M']+=1
      elsif age_group == "6 Months To < 1 year" and gender == "Female"
         @diagnosis[diagnosis]['6 MONTHS TO < 5:F']+=1
      elsif age_group == "6 Months To < 1 year" and gender == "Male"
         @diagnosis[diagnosis]['6 MONTHS TO < 5:M']+=1
      elsif age_group == "1 TO < 5" and gender == "Female"
         @diagnosis[diagnosis]['6 MONTHS TO < 5:F']+=1
      elsif age_group == "1 TO < 5" and gender == "Male"
         @diagnosis[diagnosis]['6 MONTHS TO < 5:M']+=1
      elsif age_group == "5 TO 14" and gender == "Female"
         @diagnosis[diagnosis]['5-14:F']+=1
      elsif age_group == "5 TO 14" and gender == "Male"
         @diagnosis[diagnosis]['5-14:M']+=1
      else
         if gender == "Male"
           @diagnosis[diagnosis]['>14:M']+=1
         else
           @diagnosis[diagnosis]['>14:F']+=1
         end
      end  
     }
   
    render(:layout => "layouts/menu")
  end

  def age(birthdate,obs_date,birthdate_date_created,birthdate_estimated)
    patient_age = (obs_date.year - birthdate.year) + ((obs_date.month - birthdate.month) + ((obs_date.day - birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)

    birth_date=birthdate
    estimate=birthdate_estimated
    if birth_date.month == 7 and birth_date.day == 1 and estimate == 1 and Time.now.month < birth_date.month   and birthdate_date_created.to_date.year == Time.now.year
       patient_age+=1
    end
   
    if patient_age >= 1 and patient_age < 5
      return "1 TO < 5"
    elsif patient_age >= 5 and  patient_age <= 14
      return "5 TO 14"
    elsif patient_age > 14
      return ">14"
    else 
      visit_date = obs_date.to_date.to_s ; birth_date = birthdate.to_date.to_s
      age_in_months = ActiveRecord::Base.connection.select_value("SELECT extract(MONTH FROM DATE('#{visit_date}'))-extract(MONTH FROM DATE('#{birth_date}'))").to_i
      if age_in_months > 0 and age_in_months < 6
        return "< 6 Months"
      elsif age_in_months >= 6 and age_in_months < 12
        return "6 Months To < 1 year"
      end
    end  

  end

  def referral
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'menu'
      return
    end
   
    concept_id = Concept.find_by_name("Referred to destination").id
    referred_encounter_type = EncounterType.find_by_name('Referred')
    start_date = (@start_date.to_s + " 00:00:00")
    end_date = (@end_date.to_s + " 23:59:59") 

    referals = Observation.find(:all,
                            :joins =>"INNER JOIN encounter e ON e.encounter_id = obs.encounter_id",
                            :conditions =>["e.encounter_type=? AND e.encounter_datetime >= ?
                            AND e.encounter_datetime <= ? AND obs.voided=0 AND obs.concept_id=?",
                            referred_encounter_type.id,start_date,end_date,concept_id],
                            :order => "e.encounter_id ASC",
                            :select =>"(select name from location where location_id = obs.value_numeric) AS location_name").collect{|l|l.location_name}

     @referals = Hash.new(0)
     referals.each{|location_name|
       @referals[location_name]+=1
     }
    
    render(:layout => "layouts/menu")
  end

  def report_date_select
    if params[:report] == "Total Visits" || params[:report] == "Diagnosis" || params[:report] == "Patient Level Data" || params[:report] == "Total registered" || params[:report] == "Diagnosis (By address)" 
      redirect_to :action => "select_age_group",:report_type => params[:report] 
    elsif params[:report_type] == "Patient Age Groups"
      params[:report] = params[:report_type]
      @age_groups = params[:age_groups].join(",")
    elsif params[:report_type] == "Weekly report"
      params[:report] = params[:report_type]
      @age_groups = params[:age_groups].join(",")
    elsif params[:report] == "User Stats"
      redirect_to :controller => "reports",
                  :action =>"stats_date_select",:id => "stats_menu"
    elsif params[:report] == "Return Visits"
      redirect_to :action =>"return_visits"
    elsif params[:report_type] == "Patient register"
      params[:report] = params[:report_type]
      @age_groups = params[:age_groups].join(",")
    elsif params[:report_type] == "Patient registered"
      params[:report] = params[:report_type]
      @age_groups = params[:age_groups].join(",")
    elsif params[:report_type] == "Diagnosis by address"
      params[:report] = params[:report_type]
      @age_groups = params[:age_groups].join(",")
    elsif params[:report] == "Diagnosis + demographics"
      redirect_to :action => "select_diagnosis" and return
    elsif params[:report_type] == "diagnosis_demographics"
      params[:report] = params[:report_type]
      @age_groups = params[:age_groups].join(",")
      @diagnosis = params[:diagnosis] 
    end 
  end

  def select_age_group
    if params[:report_type] == "Total Visits"
      @report_type = "Patient Age Groups"
    elsif params[:report_type] == "Diagnosis"
      @report_type = "Weekly report"
    elsif params[:report_type] == "Patient Level Data"
      @report_type = "Patient register"
    elsif params[:report_type] == "Total registered"
      @report_type = "Patient registered"
    elsif params[:report_type] == "Diagnosis (By address)"
      @report_type = "Diagnosis by address"
    elsif params[:report_type] == "Diagnosis + demographics"
      @report_type = "diagnosis_demographics"
      @diagnosis = params[:primary_diagnosis]
    end  
  end

  def select
  end

  def generate_pdf_report
    make_and_send_pdf('/report/diagnosis_report', 'diagnosis_report.pdf')
  end

  def patient_level_data
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'menu'
      return
    end
   

    concept = Concept.find_by_name('Malawi national diagnosis')
    outpatient_encounter_type = EncounterType.find_by_name('Outpatient diagnosis')
    start_date = (@start_date.to_s + " 00:00:00")
    end_date = (@end_date.to_s + " 23:59:59") 
    selected_groups = []
    params[:age_groups].split(',').each{|selected_group|
      selected_groups << "'#{selected_group}'"
    }

=begin
    patient_birthdates_diagnosis = Observation.find(:all,
      :joins =>"JOIN concept c ON obs.value_coded = c.concept_id
      JOIN encounter e ON e.encounter_id = obs.encounter_id
      JOIN patient p ON p.patient_id=obs.patient_id
      JOIN patient_name pn ON pn.patient_id=p.patient_id",
      :conditions =>["e.encounter_type=? AND e.encounter_datetime >= ?
      AND e.encounter_datetime <= ? AND obs.voided=0",
      outpatient_encounter_type.id,start_date,end_date],
      :order => "c.name ASC",
      :select => "p.birthdate AS birtdate,c.name AS name,obs.concept_id AS concept_id,obs.obs_datetime AS
      obs_date ,p.gender AS gender,pn.given_name AS first_name,pn.family_name AS last_name,p.patient_id AS patient_id,obs.value_coded AS value_coded,value_text AS drug_name").collect{|value|
        [value.birtdate,value.name,value.obs_date,value.gender,value.first_name,value.last_name,value.patient_id,value.concept_id,value.drug_name]
      }
=end

    patient_birthdates_diagnosis = Observation.find_by_sql("SELECT p.birthdate AS birtdate,c.name AS name,
      obs.concept_id AS concept_id,obs.obs_datetime AS obs_date ,p.gender AS gender,
      pn.given_name AS first_name,pn.family_name AS last_name,p.patient_id AS patient_id,
      obs.value_coded AS value_coded,value_text AS drug_name,
      age_group(p.birthdate,Date(encounter_datetime),Date(p.date_created),p.birthdate_estimated) as age_groups
      FROM `obs` JOIN concept c ON obs.value_coded = c.concept_id
      INNER JOIN encounter e ON e.encounter_id = obs.encounter_id
      INNER JOIN patient p ON p.patient_id=obs.patient_id
      INNER JOIN patient_name pn ON pn.patient_id=p.patient_id 
      WHERE (e.encounter_type=#{outpatient_encounter_type.id} AND e.encounter_datetime >= '#{start_date}'
      AND e.encounter_datetime <= '#{end_date}' AND obs.voided=0) 
      HAVING age_groups IN (#{selected_groups.join(',')}) ORDER BY c.name ASC").collect{|value|
        [value.birtdate,value.name,value.obs_date,value.gender,value.first_name,value.last_name,value.patient_id, value.concept_id,value.drug_name]
      }

     primary_diagnosis_id = Concept.find_by_name("Primary diagnosis").id
     secondary_diagnosis_id = Concept.find_by_name("Secondary diagnosis").id
     gave_drug_id = Concept.find_by_name("Drugs given").id

     @diagnosis=Hash.new()
     patient_birthdates_diagnosis.each{|patient_birthdate_diagnosis|
       birthdate,diagnosis,obs_date,gender,first_name,last_name,patient_id,diagnosis_id,drug_name = patient_birthdate_diagnosis.map {|values|values}
       next if diagnosis == "Not applicable"
       p_diagnosis = diagnosis if diagnosis_id == primary_diagnosis_id
       s_diagnosis = diagnosis if diagnosis_id == secondary_diagnosis_id
       drug_given = drug_name || diagnosis if diagnosis_id == gave_drug_id

       unless @diagnosis["#{patient_id}#{obs_date.to_date.to_s}"].blank?
         if s_diagnosis
           if @diagnosis["#{patient_id}#{obs_date.to_date.to_s}"]["secondary_diagnosis"]
             @diagnosis["#{patient_id}#{obs_date.to_date.to_s}"]["secondary_diagnosis"]+= '<br/>' + s_diagnosis 
           else
             @diagnosis["#{patient_id}#{obs_date.to_date.to_s}"]["secondary_diagnosis"] = s_diagnosis
           end  
         elsif p_diagnosis
           @diagnosis["#{patient_id}#{obs_date.to_date.to_s}"]["primary_diagnosis"] = p_diagnosis 
         else  
           if @diagnosis["#{patient_id}#{obs_date.to_date.to_s}"]["treatment"]
             @diagnosis["#{patient_id}#{obs_date.to_date.to_s}"]["treatment"]+= '<br/>' + drug_given
           else
             @diagnosis["#{patient_id}#{obs_date.to_date.to_s}"]["treatment"] = drug_given
           end  
         end  
       end  

       @diagnosis["#{patient_id}#{obs_date.to_date.to_s}"] = {"name" => "#{first_name} #{last_name}", "birthdate" => birthdate,"sex" => gender,"primary_diagnosis" => p_diagnosis,"secondary_diagnosis" => s_diagnosis,"obs_date" => obs_date,"treatment" => drug_given} if @diagnosis["#{patient_id}#{obs_date.to_date.to_s}"].blank?
     }
    
    @age_groups = []
    count = 0
    params[:age_groups].split(',').each{|group|
     @age_groups << "(#{count+=1}) #{group}  "
    }
    @age_groups = @age_groups.to_s
    @total = @diagnosis.length
    render(:layout => "layouts/menu")
  end


  def age_groups
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'menu'
      return
    end
   
    start_date = (@start_date.to_s + " 00:00:00")
    end_date = (@end_date.to_s + " 23:59:59") 
    reception_encounter = EncounterType.find_by_name('General Reception')
    concept = Concept.find_by_name("Patient present")
    yes = Concept.find_by_name("Yes").id
    selected_groups = []
    params[:age_groups].split(',').each{|selected_group|
      selected_groups << "'#{selected_group}'"
    }
    
    age_groups = Encounter.find_by_sql("SELECT age,gender,count(*) AS total FROM 
                (SELECT age_group(p.birthdate,date(obs.obs_datetime),Date(p.date_created),p.birthdate_estimated) 
                as age,p.gender AS gender
                FROM `encounter` INNER JOIN obs ON obs.encounter_id=encounter.encounter_id
                INNER JOIN patient p ON p.patient_id=encounter.patient_id WHERE
                (encounter_datetime >= '#{start_date}' AND encounter_datetime <= '#{end_date}' 
                AND encounter_type=#{reception_encounter.id} AND concept_id=#{concept.id} 
                AND value_coded=#{yes} AND obs.voided=0) order by age) AS t group by t.age,t.gender 
                HAVING t.age IN (#{selected_groups.join(',')})")
    
    @age_groups = {}
    age_groups.each{|group|
      @age_groups[group.age] = {"Female" =>0,"Male" => 0} if @age_groups[group.age].blank?
      @age_groups[group.age][group.gender] = group.total.to_i rescue 0
    }
    
    render(:layout => "layouts/menu")
  end
  
  def dash_board
    @patient = Patient.find(session[:patient_id]) rescue nil
    if @patient.blank? and params[:id]
      @patient = Patient.find(params[:id]) rescue nil
    end

    @from = params[:from]
    if @patient.blank?
      redirect_to :controller => "patient",:action => "menu" ; return
    end
    render(:layout => false)
  end  

  def return_visits
    encounter_type_id = EncounterType.find_by_name('General Reception').id
    start_date = Encounter.find(:first,
                                 :joins => "INNER JOIN obs ON encounter.encounter_id=obs.encounter_id",
                                 :conditions =>["obs.voided = 0 AND encounter_type=?",
                                 encounter_type_id],:order =>"encounter_datetime ASC")
    @start_date = start_date.encounter_datetime.to_date rescue Date.today
    @end_date = Date.today

    @visits = Encounter.find_by_sql("SELECT p.patient_id AS id,pn.given_name AS first_name ,pn.family_name 
    AS last_name,birthdate AS birthdate,p.gender AS gender, (SELECT encounter_datetime 
    FROM encounter t WHERE t.patient_id = e.patient_id and t.encounter_type=#{encounter_type_id} 
    ORDER BY t.encounter_datetime limit 1) AS first_visit_date,count(*) as number_of_visits 
    FROM `encounter` e 
    INNER JOIN obs ON obs.encounter_id=e.encounter_id
    INNER JOIN patient p ON p.patient_id=e.patient_id 
    INNER JOIN patient_name pn ON p.patient_id=pn.patient_id 
    WHERE (encounter_type=#{encounter_type_id} AND obs.voided=0) 
    group by e.patient_id  having  number_of_visits > 1 order by family_name asc")
 
    render(:layout => false)
  end

  def total_registered
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'menu'
      return
    end
   
    start_date = (@start_date.to_s + " 00:00:00")
    end_date = (@end_date.to_s + " 23:59:59") 
    reception_encounter = EncounterType.find_by_name('General Reception')
    concept = Concept.find_by_name("Patient present")
    identifier_type=PatientIdentifierType.find_by_name("Traditional authority").id
    yes = Concept.find_by_name("Yes").id
    selected_groups = []
    params[:age_groups].split(',').each{|selected_group|
      selected_groups << "'#{selected_group}'"
    }
    
    @patients = Patient.find_by_sql("SELECT pn.given_name AS first_name,pn.family_name AS last_name,
       p.birthdate AS birthdate,p.gender AS sex,p.date_created AS reg_date,pd.city_village AS address,
       i.identifier as ta,age_group(p.birthdate,Date(encounter_datetime),Date(p.date_created),
       p.birthdate_estimated) as age_groups FROM patient p 
       INNER JOIN encounter e ON e.patient_id = p.patient_id
       INNER JOIN obs ON obs.encounter_id = e.encounter_id
       INNER JOIN patient_name pn ON p.patient_id = pn.patient_id
       INNER JOIN patient_address pd ON p.patient_id = pd.patient_id
       INNER JOIN patient_identifier i ON p.patient_id = i.patient_id 
       AND i.identifier_type=#{identifier_type}
       WHERE (e.encounter_type=#{reception_encounter.id} 
       AND p.date_created >= '#{start_date}' AND p.date_created <= '#{end_date}' AND obs.voided=0 
       AND obs.value_coded=#{yes}) AND obs.concept_id=#{concept.id}
       GROUP BY p.patient_id
       HAVING age_groups IN (#{selected_groups.join(',')})
       ORDER BY pn.family_name ASC")

    @age_groups = []
    count = 0
    params[:age_groups].split(',').each{|group|
     @age_groups << "(#{count+=1}) #{group}  "
    }
    @age_groups = @age_groups.to_s
    render(:layout => "layouts/menu")
  end

  def diagnosis_by_address
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'menu'
      return
    end
   
    start_date = (@start_date.to_s + " 00:00:00")
    end_date = (@end_date.to_s + " 23:59:59") 
    diagnosis_ids = []
    diagnosis_ids << Concept.find_by_name('Primary diagnosis').id
    diagnosis_ids << Concept.find_by_name('Secondary diagnosis').id
    outpatient_encounter_type = EncounterType.find_by_name('Outpatient diagnosis')
    selected_groups = []
    params[:age_groups].split(',').each{|selected_group|
      selected_groups << "'#{selected_group}'"
    }
    
    diagnosis = Concept.find_by_sql("SELECT `concept`.*,pd.city_village AS address , age_group(p.birthdate,
       Date(encounter_datetime),Date(p.date_created),
       p.birthdate_estimated) as age_groups FROM `concept` 
       INNER JOIN obs ON obs.value_coded = concept.concept_id
       INNER JOIN encounter e ON e.encounter_id = obs.encounter_id 
       INNER JOIN patient p ON p.patient_id=e.patient_id
       INNER JOIN patient_address pd ON p.patient_id=pd.patient_id
       WHERE (e.encounter_type=#{outpatient_encounter_type.id} 
       AND e.encounter_datetime >= '#{start_date}'
       AND e.encounter_datetime <= '#{end_date}' AND obs.voided=0 
       AND obs.concept_id IN (#{diagnosis_ids.join(',')})) 
       HAVING age_groups IN (#{selected_groups.join(',')})
       ORDER BY age_groups DESC")

    @diagnosis = Hash.new(0)
    diagnosis.each{|diagno|
      next if diagno.name == "Not applicable"
      @diagnosis["#{diagno.name} @ #{diagno.address}"]+=1
    }
    @age_groups = []
    count = 0
    params[:age_groups].split(',').each{|group|
     @age_groups << "(#{count+=1}) #{group}  "
    }
    @age_groups = @age_groups.to_s
    render(:layout => "layouts/menu")
  end
 
  def diagnosis_plus_demographics
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'menu'
      return
    end
   
    start_date = (@start_date.to_s + " 00:00:00")
    end_date = (@end_date.to_s + " 23:59:59") 
    diagnosis_ids = []
    diagnosis_ids << Concept.find_by_name('Primary diagnosis').id
    diagnosis_ids << Concept.find_by_name('Secondary diagnosis').id
    outpatient_encounter_type = EncounterType.find_by_name('Outpatient diagnosis')
    selected_groups = []
    params[:age_groups].split(',').each{|selected_group|
      selected_groups << "'#{selected_group}'"
    }
    
    values = Concept.find_by_sql("SELECT p.patient_id AS patient_id,pn.given_name AS first_name,pn.family_name AS last_name,
       p.birthdate,Date(e.encounter_datetime) as visit_date,p.gender,
       concept.name, age_group(p.birthdate,
       Date(encounter_datetime),Date(p.date_created),
       p.birthdate_estimated) as age_groups ,pi.identifier AS physical_address
       FROM `concept` 
       INNER JOIN obs ON obs.value_coded = concept.concept_id
       INNER JOIN encounter e ON e.encounter_id = obs.encounter_id 
       INNER JOIN patient p ON p.patient_id=e.patient_id
       INNER JOIN patient_name pn ON p.patient_id=pn.patient_id
       INNER JOIN patient_identifier pi ON p.patient_id=pi.patient_id 
       WHERE (e.encounter_type=#{outpatient_encounter_type.id}
       AND e.encounter_datetime >= '#{start_date}'
       AND e.encounter_datetime <= '#{end_date}' AND obs.voided=0 
       AND obs.concept_id IN (#{diagnosis_ids.join(',')})) AND name = '#{params[:diagnosis]}'
       AND pi.identifier_type = 6
       HAVING age_groups IN (#{selected_groups.join(',')})
       ORDER BY age_groups DESC").collect{|value|
        [value.patient_id,value.birthdate,value.name,value.gender,value.age_groups,value.visit_date,value.last_name,
         value.first_name,value.physical_address,value.name]
      }


    @diagnosis = {}
    values.each{|value|
     if  @diagnosis[value[0].to_i].blank?
      @diagnosis[value[0].to_i] = {"name" => "#{value[6]} #{value[7]}","sex" => value[3],"diagnosis" => value[9],
      "birthdate" => value[1],"age_group" => value[4],"address" => "#{value[8].strip rescue nil}","visit_date" => value[5]}
     else
      @diagnosis[value[0].to_i]["visit_date"]+= "</br>#{value[5]}"
     end
    }

    @age_groups = []
    count = 0
    params[:age_groups].split(',').each{|group|
     @age_groups << "(#{count+=1}) #{group}  "
    }
    @age_groups = @age_groups.to_s

    render(:layout => "layouts/menu")
  end

  def select_diagnosis
    concept = Concept.find_by_name('Malawi national diagnosis')
    diagnosis_concepts = Concept.find(:all, :joins => :concept_sets,
                                      :conditions => ['concept_set = ?', concept.concept_id],:order =>"name ASC")
    @options = ['']
    diagnosis_concepts.collect{|concept|
      next if concept.name == 'Malawi national diagnosis'
      next if concept.name == 'Not applicable'
      @options << concept.name
    }
  end

end
