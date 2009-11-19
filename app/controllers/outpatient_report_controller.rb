class OutpatientReportController < ApplicationController
#  include PdfHelper
  def menu
  end

  def weekly_report
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'select'
      return
    end
   

    concept = Concept.find_by_name('MALAWI NATIONAL DIAGNOSIS')
    outpatient_encounter_type = EncounterType.find_by_name('Outpatient diagnosis')

    diagnosis_concepts = Concept.find(:all, :joins => :concept_sets,
                                      :conditions => ['concept_set = ?', concept.concept_id])

    diagnosis = Concept.find(:all,
                                  :joins =>"INNER JOIN obs ON obs.value_coded = concept.concept_id
                                  INNER JOIN encounter e ON e.encounter_id = obs.encounter_id",
                                  :conditions =>["e.encounter_type=? AND Date(e.encounter_datetime) >= ?
                                  AND Date(e.encounter_datetime) <= ? AND obs.voided=0",
                                  outpatient_encounter_type.id,@start_date,@end_date],
                                  :order => "concept.name ASC")
     @diagnosis = Hash.new(0)
     diagnosis.each{|diagno|
       next if diagno.name == "NOT APPLICABLE"
       @diagnosis[diagno.name]+=1
     }
    
    render(:layout => "layouts/menu")
  end

  def disaggregated_diagnosis
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'select'
      return
    end
   

    concept = Concept.find_by_name('MALAWI NATIONAL DIAGNOSIS')
    outpatient_encounter_type = EncounterType.find_by_name('Outpatient diagnosis')

    diagnosis_concepts = Concept.find(:all, :joins => :concept_sets,
                                      :conditions => ['concept_set = ?', concept.concept_id])

    patient_birtdates_diagnosis = Observation.find(:all,
      :joins =>"INNER JOIN concept c ON obs.value_coded = c.concept_id
      INNER JOIN encounter e ON e.encounter_id = obs.encounter_id
      INNER JOIN patient p ON p.patient_id=obs.patient_id",
      :conditions =>["e.encounter_type=? AND Date(e.encounter_datetime) >= ?
      AND Date(e.encounter_datetime) <= ? AND obs.voided=0",
      outpatient_encounter_type.id,@start_date,@end_date],
      :order => "c.name ASC",
      :select => "p.birthdate AS birtdate,c.name AS name,obs.obs_datetime AS obs_date ,p.gender AS gender").collect{|value|[value.birtdate,value.name,value.obs_date,value.gender]}

     @diagnosis=Hash.new()
     patient_birtdates_diagnosis.each{|patient_birtdate_diagnosis|
       birtdate,diagnosis,obs_date,gender = patient_birtdate_diagnosis.map {|values|values}
       next if diagnosis == "NOT APPLICABLE"
       age_group = age(birtdate.to_date,obs_date.to_date)
       @diagnosis[diagnosis] = {"U5:M" => 0, "5-14:M" => 0, ">14:M" => 0,"U5:F" => 0, "5-14:F" => 0, ">14:F" => 0} if @diagnosis[diagnosis].blank?
       if age_group == "U5" and gender == "Female"
          @diagnosis[diagnosis]['U5:F']+=1
       elsif age_group == "U5" and gender == "Male"
          @diagnosis[diagnosis]['U5:M']+=1
       elsif age_group == "5-14" and gender == "Female"
          @diagnosis[diagnosis]['5-14:F']+=1
       elsif age_group == "5-14" and gender == "Male"
          @diagnosis[diagnosis]['U5:M']+=1
       elsif age_group == ">14" and gender == "Female"
          @diagnosis[diagnosis]['>14:F']+=1
       elsif age_group == ">14" and gender == "Male"
          @diagnosis[diagnosis]['>14:M']+=1
       end  
     }
    
    render(:layout => "layouts/menu")
  end

  def age(birthdate,obs_date)
    patient_age = (obs_date.year - birthdate.year) + ((obs_date.month - birthdate.month) + ((obs_date.day - birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)
   
    if patient_age < 5
      return "U5"
    elsif patient_age >= 5 and  patient_age <= 14
      return "5-14"
    else
      return ">14"
    end
  end

  def referral
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if (@start_date > @end_date) || (@start_date > Date.today)
      flash[:notice] = 'Start date is greater than end date or Start date is greater than today'
      redirect_to :action => 'select'
      return
    end
   
    concept_id = Concept.find_by_name("Referred to destination").id
    referred_encounter_type = EncounterType.find_by_name('Referred')

    referals = Observation.find(:all,
                            :joins =>"INNER JOIN encounter e ON e.encounter_id = obs.encounter_id",
                            :conditions =>["e.encounter_type=? AND Date(e.encounter_datetime) >= ?
                            AND Date(e.encounter_datetime) <= ? AND obs.voided=0 AND obs.concept_id=?",
                            referred_encounter_type.id,@start_date,@end_date,concept_id],
                            :order => "e.encounter_id ASC",
                            :select =>"(select name from location where location_id = obs.value_numeric) AS location_name").collect{|l|l.location_name}

     @referals = Hash.new(0)
     referals.each{|location_name|
       @referals[location_name]+=1
     }
    
    render(:layout => "layouts/menu")
  end

  def report_date_select
  end
  
  def select
  end

  def generate_pdf_report
    make_and_send_pdf('/report/weekly_report', 'weekly_report.pdf')
  end


end
