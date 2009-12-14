class OutpatientReportController < ApplicationController
#  include PdfHelper
  def menu
  end

  def weekly_report
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'menu'
      return
    end
   
    start_date = (@start_date.to_s + " 00:00:00")
    end_date = (@end_date.to_s + " 23:59:59") 
    concept = Concept.find_by_name('Malawi national diagnosis')
    outpatient_encounter_type = EncounterType.find_by_name('Outpatient diagnosis')

    diagnosis = Concept.find(:all,
                             :joins =>"INNER JOIN obs ON obs.value_coded = concept.concept_id
                             INNER JOIN encounter e ON e.encounter_id = obs.encounter_id",
                             :conditions =>["e.encounter_type=? AND e.encounter_datetime >= ?
                             AND e.encounter_datetime <= ? AND obs.voided=0",
                             outpatient_encounter_type.id,start_date,end_date],
                             :order => "concept.name ASC")

    @diagnosis = Hash.new(0)
    diagnosis.each{|diagno|
      next if diagno.name == "Not applicable"
      @diagnosis[diagno.name]+=1
    }
    
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
    concept = Concept.find_by_name('Malawi national diagnosis')
    outpatient_encounter_type = EncounterType.find_by_name('Outpatient diagnosis')

    patient_birtdates_diagnosis = Observation.find(:all,
      :joins =>"INNER JOIN concept c ON obs.value_coded = c.concept_id
      INNER JOIN encounter e ON e.encounter_id = obs.encounter_id
      INNER JOIN patient p ON p.patient_id=obs.patient_id",
      :conditions =>["e.encounter_type=? AND e.encounter_datetime >= ?
      AND e.encounter_datetime <= ? AND obs.voided=0",
      outpatient_encounter_type.id,@start_date,@end_date],
      :order => "c.name ASC",
      :select => "p.birthdate AS birtdate,c.name AS name,obs.obs_datetime AS obs_date ,p.gender AS gender,p.date_created AS patient_date_created,p.birthdate_estimated AS birthdate_estimated").collect{|value|[value.birtdate,value.name,value.obs_date,value.gender,value.patient_date_created,value.birthdate_estimated]}

    @diagnosis=Hash.new()
    patient_birtdates_diagnosis.each{|patient_birtdate_diagnosis|
      birtdate,diagnosis,obs_date,gender,patient_date_created,birtdate_estimated = patient_birtdate_diagnosis.map {|values|values}
      next if diagnosis == "Not applicable"
      next if birtdate.blank?
      age_group = age(birtdate.to_date,obs_date.to_date,patient_date_created,birtdate_estimated)
      @diagnosis[diagnosis] = {"< 6 MONTHS:M" => 0,"< 6 MONTHS:F" =>0,">14:M" => 0,"6 MONTHS TO < 5:F" => 0,"6 MONTHS TO < 5:M" =>0,">14:F" => 0,"5-14:F" => 0,"5-14:M" =>0} if @diagnosis[diagnosis].blank?

      if age_group == "< 6 Months" and gender == "Female"
         @diagnosis[diagnosis]['< 6 MONTHS:F']+=1
      elsif age_group == "< 6 Months" and gender == "Male"
         @diagnosis[diagnosis]['< 6 MONTHS:M']+=1
      elsif age_group == "6 Months To < 1 year" and gender == "Male"
         @diagnosis[diagnosis]['6 MONTHS TO < 5:M']+=1
      elsif age_group == "6 Months To < 1 year" and gender == "Female"
         @diagnosis[diagnosis]['6 MONTHS TO < 5:F']+=1
      elsif age_group == "1 TO < 5" and gender == "Female"
         @diagnosis[diagnosis]['6 MONTHS TO < 5:F']+=1
      elsif age_group == "1 TO < 5" and gender == "Male"
         @diagnosis[diagnosis]['6 MONTHS TO < 5:F']+=1
      elsif age_group == "5 TO 14" and gender == "Female"
         @diagnosis[diagnosis]['5-14:F']+=1
      elsif age_group == "5 TO 14" and gender == "Male"
         @diagnosis[diagnosis]['5-14:M']+=1
      elsif age_group == ">14" and gender == "Female"
         @diagnosis[diagnosis]['>14:F']+=1
      elsif age_group == ">14" and gender == "Male"
         @diagnosis[diagnosis]['>14:M']+=1
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
    if params[:report] == "Patient Age Groups"
      redirect_to :action => "select_age_group" ; return
    elsif params[:report_type] == "Patient Age Groups"
      params[:report] = params[:report_type]
      @age_groups = params[:age_groups].join(",")
    elsif params[:report] == "User Stats"
      redirect_to :controller => "reports",
                  :action =>"stats_date_select",:id => "stats_menu"
    end 
  end

  def select_age_group
  end

  def select
  end

  def generate_pdf_report
    make_and_send_pdf('/report/weekly_report', 'weekly_report.pdf')
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
    @patient = Patient.find(session[:patient_id])
    if @patient.blank? and params[:id]
      @patient = Patient.find(params[:id])
    end
    render(:layout => false)
  end  

  def return_visits
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'menu'
      return
    end
   
    start_date = (@start_date.to_s + " 00:00:00")
    end_date = (@end_date.to_s + " 23:59:59")
    encounter_type_id = EncounterType.find_by_name('General Reception').id

    @visits = Patient.find(:all,
                 :joins => "INNER JOIN encounter e ON e.patient_id=patient.patient_id 
                 INNER JOIN obs ON e.encounter_id=obs.encounter_id
                 INNER JOIN patient_name pn ON patient.patient_id=pn.patient_id",
                 :conditions =>["encounter_datetime >='#{start_date}' AND encounter_datetime <= '#{end_date}'
                 AND encounter_type=? AND obs.voided=0",encounter_type_id],
                 :select => "pn.given_name AS first_name ,pn.family_name AS last_name,
                 patient.birthdate AS birthdate,Date(obs.obs_datetime) AS visit_date,count(*) AS
                 number_of_visits,patient.gender AS gender",
                 :group => "e.patient_id HAVING number_of_visits > 1",
                 :order => "pn.family_name,encounter_datetime ASC")
  
    render(:layout => false)
  end
#[value.first_name,value.last_name,value.visit_date,value.sex,value.birthdate,value.visit]}
end
