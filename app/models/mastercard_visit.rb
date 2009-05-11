class MastercardVisit
  
  attr_accessor :date, :weight, :height, :bmi, :outcome, :reg, :confirmed_tb, :suspected_tb, :s_eff, :sk , :pn, :hp, :pills, :gave, :cpt, :cd4,:estimated_date,:next_app, :tb_status, :doses_missed, :visit_by, :date_of_outcome, :reg_type, :adherence


  def self.visit(patient,date = Date.today)
    visits = self.new()
    symptoms = []
    remaining_pills = []
    concept_names = Concept.find_by_name('Symptoms').answer_options.collect{|option| option.name}
    concept_names += Concept.find_by_name('Symptoms continued..').answer_options.collect{|option| option.name}
    concept_names+= ["Weight","Height","Prescribe Cotrimoxazole (CPT)","ARV regimen"]
      concept_names.each{|concept_name|
      observations = Observation.find(:all,:conditions => ["voided = 0 and Date(obs_datetime)='#{date}' and concept_id=? and patient_id=?",(Concept.find_by_name(concept_name).id),patient.patient_id],:order=>"obs.obs_datetime desc")
      observations.each{|observation|
      case concept_name
        when "Weight"
          visits.weight=observation.value_numeric 
        when "Height"
          visits.height = observation.value_numeric 
        when "Prescribe Cotrimoxazole (CPT)"
          pills_given=patient.drug_orders_for_date(observation.obs_datetime)
          if pills_given
            pills_given.each{|names|
            if names.drug.name=="Cotrimoxazole 480"
              visits.cpt = names.quantity # observation.result_to_string
            end
            }
          end
        else
          unless observation.blank?
            ans = observation.answer_concept.name 
            symptoms << observation.concept.short_name if ans == "Yes drug induced" and !observation.concept.short_name.blank?
          end
        end
      }

    }


    #the following code pull out the number of tablets given to a patient per visit
    number_of_pills_given = self.drugs_given(patient,date)
    unless  number_of_pills_given.blank?
      visits.reg = number_of_pills_given.map{|reg_type,drug_quantity_given|drugs_quantity = drug_quantity_given.split(":")[1]
                                        drugs_quantity.split(";").collect{|x|x}}.compact.uniq.first
      
      drugs_given_to_patient =  patient.patient_present?(date)
      drugs_given_to_guardian =  patient.guardian_present?(date)
      drugs_given_to_both_patient_and_guardian =  patient.patient_and_guardian_present?(date)
      visits.reg_type = number_of_pills_given.collect{|type,values|type}.to_s rescue nil

      visits.visit_by = "Guardian seen" if drugs_given_to_guardian
      visits.visit_by = "Patient seen" if drugs_given_to_patient
      visits.visit_by = "Pat & Grdn seen" if drugs_given_to_both_patient_and_guardian
    end
         
          
    visits.height = patient.current_height if visits.height.blank?
    unless visits.height.blank? and visits.weight.blank? then
      bmi=(visits.weight.to_f/(visits.height.to_f**2)*10000)
      visits.bmi = sprintf("%.1f", bmi)
    end

    visits.tb_status = patient.tb_status(date)
    visits.adherence = patient.adherence(date)
    visits.next_app = patient.next_appointment_date(date)
    visits.cpt = 0 if visits.cpt.blank?
    visits.outcome = self.outcome_abb(patient.outcome(date).name) rescue nil
    visits.date_of_outcome = patient.outcome_date(date) if visits.outcome != "Alve"  
    symptoms.collect{|side_eff|if visits.s_eff.blank? then visits.s_eff = side_eff.to_s else visits.s_eff+= "," + side_eff.to_s end} 
    visits.s_eff = "None" if visits.s_eff.blank?

    visits
  end

  def self.outcome_abb(outcome)
   case outcome
     when "Defaulter"
       return "Def"
     when "Transfer Out"
       return "TO"
     when "Transfer Out(With Transfer Note)" 
       return "TO"
     when "Transfer Out(Without Transfer Note)"
       return "TO"
     when "ART Stop"
       return "Stop"
     when "Died"
       return "Died"
     else
       return "Alve"
    end
  end

  def self.drugs_given(patient,date)
    patient_regimems = PatientHistoricalRegimen.find_by_sql("select * from (select * from patient_historical_regimens where                 patient_id=#{patient.id} and date(dispensed_date)='#{date}' order by dispensed_date) as regimen group by regimen_concept_id")
    
    start_dates = {}
    patient_regimems.each{|regimen|
      regimen_name = regimen.concept.concept_sets.first.name
      dispensed_drugs = []
      regimen.encounter.drug_orders.collect{|order|dispensed_drugs << "#{order.drug.short_name.strip} (#{order.quantity.to_s});" unless order.drug.name =="Cotrimoxazole 480"}.uniq.compact
      start_dates[regimen_name] = "#{regimen.encounter.encounter_datetime.to_date.to_s}:#{dispensed_drugs.uniq.to_s.strip}"
    }

    start_dates
  end

end
