class MastercardVisit
  
  attr_accessor :date, :weight, :height, :bmi, :outcome, :reg, :amb, :wrk_sch, :s_eff, :sk , :pn, :hp, :pills, :gave, :cpt, :cd4,:estimated_date,:next_app, :tb_status, :doses_missed


  def self.visit(patient,date = Date.today)
    visits = self.new()
    symptoms = []
    remaining_pills = []
    concept_names = Concept.find_by_name('Symptoms').answer_options.collect{|option| option.name}
    concept_names += Concept.find_by_name('Symptoms continued..').answer_options.collect{|option| option.name}
    concept_names+= ["Weight","Height","Prescribe Cotrimoxazole (CPT)","Whole tablets remaining and brought to clinic","CD4 count","ARV regimen"]
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
        when "Whole tablets remaining and brought to clinic"
          unless observation.blank?
            pills_left= observation.value_numeric
            pills_left=pills_left.to_i unless pills_left.nil? and !pills_left.to_s.strip[-2..-1]==".0"
            if pills_left !=0 and !pills_left.blank?
              remaining_pills << "#{observation.drug.short_name} (#{pills_left.to_s})" 
            end
          end
        when "CD4 count"
          unless observation.blank?
            value_modifier = observation.value_modifier
            if value_modifier.blank? || value_modifier =="=" || value_modifier==""
              cd_4=observation.value_numeric
              cd_4="Unknown" if observation.value_numeric==0.0
              visits.cd4 =cd_4
            else
              visits.cd4 = value_modifier + observation.value_numeric.to_s
            end
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
    number_of_pills_given = patient.drugs_given_last_time(date)
    unless  number_of_pills_given.blank?
      visits.reg = number_of_pills_given.map{|drug,quantity_given|drug.short_name}.compact.uniq
      drugs_given_to_patient =  patient.patient_present?(date)
      drugs_given_to_guardian =  patient.guardian_present?(date)
      drugs_given_to_both_patient_and_guardian =  patient.patient_and_guardian_present?(date)
      total_quantity_given = ""

      number_of_pills_given.each{|drug,quantity|
        total_quantity_given+= " " + drug.short_name + ": " + "(#{quantity.to_s})" if !total_quantity_given.blank? and !drug.short_name.blank?
        total_quantity_given = drug.short_name + ": " + "(#{quantity.to_s})" if total_quantity_given.blank? and !drug.short_name.blank?
      }
      visits.gave = "G: " + total_quantity_given if drugs_given_to_guardian
      visits.gave = "P: " + total_quantity_given if drugs_given_to_patient
      visits.gave = "PG: " + total_quantity_given if drugs_given_to_both_patient_and_guardian
      if !drugs_given_to_guardian and !drugs_given_to_patient and !drugs_given_to_both_patient_and_guardian
        visits.gave = total_quantity_given
      end
    end
         
          
    visits.height = patient.current_height if visits.height.blank?
    unless visits.height.blank? and visits.weight.blank? then
      bmi=(visits.weight.to_f/(visits.height.to_f**2)*10000)
      visits.bmi = sprintf("%.1f", bmi)
    end

    visits.pills = remaining_pills.uniq
    visits.tb_status = patient.tb_status(date)
    visits.doses_missed = patient.doses_unaccounted_for_and_doses_missed(date).split(":")[1] rescue "0"
    visits.next_app = patient.next_appointment_date(date)
    visits.outcome = self.outcome_abb(patient.outcome(date).name) rescue nil
    symptoms.collect{|side_eff|if visits.s_eff.blank? then visits.s_eff = side_eff.to_s else visits.s_eff+= "," + side_eff.to_s end} 

    visits
  end

  def self.by_patient_and_date(patient,date=Date.today)
    visit = self.visit(patient,date)
    data = {}
    data["height"] = "20",visit.height.to_i.to_s if visit.height
    data["weight"] = "65",visit.weight.to_s if visit.weight
    data["outcome"] = "140","Alv" if visit.outcome
    data["outcome_date"] = "200",date.strftime("%d/%m") if visit.outcome
    data["outcome_date2"] = "200",date.strftime("%Y") if visit.outcome
    data["tb_status"] = "380",visit.tb_status[0..3] if visit.tb_status
    data["doses_missed"] = "490",visit.doses_missed[0..2] if visit.doses_missed
    data["cpt"] = "620",visit.cpt.to_s if visit.cpt
    data["bmi"] = "670",visit.bmi.to_s if visit.bmi
    data["app_date"] = "730",visit.next_app.strftime("%d/%m") if visit.next_app
    data["app_date2"] = "730",visit.next_app.strftime("%Y") if visit.next_app

    count = 1
    visit.s_eff.split(",").each{|side_eff|
      data["side_eff#{count}"] = "320",side_eff[0..3] + " "
      count+=1
    } if visit.s_eff

    count = 1
    visit.gave.gsub(":","").split(" ").each{|pills_gave|
      data["arv_given#{count}"] = "540",pills_gave if pills_gave.include?("(")
      data["arv_given#{count}"] = "540",pills_gave[0..2] if !pills_gave.include?("(")
      count+= 1
    } if visit.gave

    count = 1
    visit.reg.each{|reg| 
      reg.split(" ").each{|name|
        data["art_reg#{count}"] = "270",name[0..2] + " "
        count+= 1
      } 
    } if visit.reg
  
    count = 1
    visit.pills.each{|pills| 
      pills.split(" ").each{|pill|
        data["pill_count#{count}"] = "440",pill if pills.include?("(")
        data["pill_count#{count}"] = "440",pill[0..2] if !pills.include?("(")
        count+= 1
      }
    } if visit.pills

    data
  end

  def self.outcome_abb(outcome)
   case outcome
     when "Defaulter"
       return "Def"
     when outcome.include?("Transfer Out")
       return "Def"
     when "ART Stop"
       return "Stop"
     when "Died"
       return "Died"
     else
       return "Alve"
    end
  end

end
