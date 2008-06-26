class Mastercard < Patient
  
  #  This model is obsolete and is never used in BART
  #  * It only has one reference: Patient.mastercard - which is never called
  #  * It uses Encounter Types 'ART Initiation' and 'ART Transfer in', which do not exist, to determine if patient Transferred in or not
  #  -- 2008-06-26 Soyapi

  attr_reader :arv_id, :national_id, :pt_name, :age, :sex
  attr_reader :init_wt, :init_ht, :bmi, :transfer, :address, :occupation
  attr_reader :hiv_test, :diseases, :date_of_first_arv, :reason
  attr_reader :date_of_alt_arv1, :date_of_alt_arv2
  attr_reader :prev_visits
    
def initialize(patient)
    patient_id = patient.patient_id
    birthdate = patient.birthdate

#*** find ART initiation encounter object ***

     unless
        (init_encounter = Encounter.find(:first, :conditions => ["patient_id=? AND encounter_type=?", patient_id, EncounterType.find_by_name("ART Initiation").encounter_type_id])).nil?
        @transfer = "No"
     else
        init_encounter = Encounter.find(:first, :conditions => ["patient_id=? AND encounter_type=?", patient_id, EncounterType.find_by_name("ART Transfer in").encounter_type_id])
        @transfer = "Yes"
     end

#*** a few demographic data
		@arv_id = ""
    @arv_id_obj = (PatientIdentifier.find_by_patient_id_and_identifier_type(patient_id, PatientIdentifierType.find_by_name("Arv national id").id))
    @arv_id = @arv_id_obj.identifier unless @arv_id_obj.nil?
    @national_id = (PatientIdentifier.find_by_patient_id_and_identifier_type(patient_id, PatientIdentifierType.find_by_name("national id").id)).identifier
    @occupation = (PatientIdentifier.find_by_patient_id_and_identifier_type(patient_id, PatientIdentifierType.find_by_name("occupation").id)).identifier
  
#*** Compose address using physical address and name of tradition authority ***
       street_address = (PatientIdentifier.find_by_patient_id_and_identifier_type(patient_id, PatientIdentifierType.find_by_name("physical address").id)).identifier
       ta = (PatientIdentifier.find_by_patient_id_and_identifier_type(patient_id, PatientIdentifierType.find_by_name("traditional authority").id)).identifier
       @address = street_address + " " + ta

#*** Name ***
    name = PatientName.find_by_patient_id(patient_id)
      if (name.middle_name.nil?)      
        @pt_name = name.given_name + " " + name.family_name
      else
        @pt_name = name.given_name + " " + name.middle_name + " " + name.family_name
      end

#*** Calculate age based on current date minus date of birthday ***
      now = Time.now
      day_diff = now.day - patient.birthdate.day
      month_diff = now.month - patient.birthdate.month - (day_diff < 0 ? 1 :0)
        @age = now.year - patient.birthdate.year - (month_diff < 0 ? 1 : 0) 

    @sex = patient.gender

#*** Ht and Wt at start of ARV *** 
    if ((encounter_wt = init_encounter.observations.find_by_concept_id(Concept.find_by_name("Weight").concept_id)).empty?)
       @init_wt = "?"
    else
       # find init_wt    
       @init_wt = encounter_wt.first.value_numeric
    end

    if ((encounter_ht = init_encounter.observations.find_by_concept_id(Concept.find_by_name("Weight").concept_id)).empty?)
       @init_ht = "?"
    else
       # find init_ht
       @init_ht = encounter_ht.first.value_numeric
    end

#*** BMI is calculated using... ***
    @bmi = "to be calculated"  # awaiting BMI calculation formula

#*** date and loc of positive HIV test ***
    hiv_test = init_encounter.observations.find_by_concept_id(Concept.find_by_name("Date of first positive HIV Test").concept_id)
    if (hiv_test.empty?)
       @hiv_test = "?"
    else
       if ((datetime_hiv_test = hiv_test.first.value_datetime).nil?)
          @hiv_test = "?"  
       else
          @hiv_test = datetime_hiv_test.year.to_s << "-" << datetime_hiv_test.month.to_s << "-" << datetime_hiv_test.day.to_s  
       end
    end 

    hiv_test =  init_encounter.observations.find_by_concept_id(Concept.find_by_name("Location of first positive HIV Test").concept_id) 
    if (hiv_test.empty?)
       @hiv_test << " / ? "
    else
       (hiv_test.first.value_text.nil?) ? (@hiv_test << " / ?") : (@hiv_test << " / " << hiv_test.first.value_text)
    end

#*** date of ARV initiation ***
       if ((first_arv = init_encounter.observations.find_by_concept_id(Concept.find_by_name("Date of ART initiation").concept_id)).empty?)
          first_arv_date = "Date: N/A"
       else
          first_arv_dateimte = first_arv.first.obs_datetime
          first_arv_date = first_arv_datetime.year.to_s << "-" << first_arv_datetime.month.to_s << "-" << first_arv_datetime.day.to_s
      end

#*** initial ARV regimen ***
       if ((first_arv = init_encounter.observations.find_by_concept_id(Concept.find_by_name("ARV formulation").concept_id)).empty?)
          first_arv_reg = "Regimen: N/A"
       else
          first_arv_reg = first_arv.first.value_drug
      end
    @date_of_first_arv = first_arv_date << " / "<< first_arv_reg

#*** WHO reason for ARV ***
    @reason = (reason = init_encounter.observations.find_by_concept_id(Concept.find_by_name("Reason antiretrovirals started")).empty?) ? "N/A" : reason.first.text_value

#*** WHO staging diseases ***
    #@diseases = "from tbl obs"  #PTB(295), EPTB(10), KS(285), PMTCT(17)
    # from patient initial visit encounter, loop through all obs, if a disease concept belongs to a concept set that links
    # to a WHO ARV stage (concept.set_concepts) and has an answer yes, then display it
    # display the short name of a concept if available  output = concept.short_name ? concept.short_name : concept.name

    disease_array = init_encounter.observations.collect  { |f|  if (Concept.find_by_concept_id(f.concept_id).class_id == ConceptClass.find_by_name("Diagnosis").concept_class_id); concept = Concept.find_by_concept_id(f.concept_id); concept.short_name ? concept.short_name : output.name;  end }.compact

    if (disease_array.empty?)
        @diseases = "None"
    else
        @diseases = disease_array.to_param
    end

#*** ARV substitue and switch ****
    if ((alt_arv1 = init_encounter.observations.find_by_concept_id(Concept.find_by_name("Substitute").concept_id)).empty?)
        @date_of_alt_arv1 = "N/A"
    else
        alt_arv1_datetime = alt_arv1.first.obs_datetime
        @date_of_alt_arv1 = alt_arv1_datetime.year.to_s << "-" << alt_arv1_datetime.month.to_s << "-" << alt_arv1_datetime.day.to_s
        # also specify which regiment
    end

    if ((alt_arv2 = init_encounter.observations.find_by_concept_id(Concept.find_by_name("Substitute").concept_id)).empty?)
        @date_of_alt_arv2 = "N/A"
    else
        alt_arv2_datetime = alt_arv2.first.obs_datetime
        @date_of_alt_arv2 = alt_arv2_datetime.year.to_s << "-" << alt_arv2_datetime.month.to_s << "-" << alt_arv2_datetime.day.to_s
        # also specify which regimen
    end

#*** Check for previous visits ***
    if (not (prev_visits_obj = (Encounter.find(:all, :conditions => ["patient_id=? AND encounter_type !=?", patient_id, EncounterType.find_by_name("ART Initiation").encounter_type_id], :order => "encounter_id desc"))))
       @prev_visits = "no previous visits"
    else
       #based on the number of previous visits, 
       #create an arrays of previous visits data
       #find previous visits via encounter 
       @prev_visits = Array.new
          prev_visits_obj.each  { | pt_encounter_obj | prev_visits.push(MastercardVisit.new(pt_encounter_obj, self.concept_id_var))  } 
    end       

       # lines below are just for testing the previous visits view - to be deleted in production
#          @prev_visits = Array.new
#          prev_visits.push(MastercardVisit.new(patient))
#          prev_visits.push(MastercardVisit.new(patient))
#          prev_visits.push(MastercardVisit.new(patient))
#          prev_visits.push(MastercardVisit.new(patient))
#          prev_visits.push(MastercardVisit.new(patient))
#          prev_visits.push(MastercardVisit.new(patient))
#          prev_visits[1].instance_variable_set(:@date, "2000-11-10")
#          prev_visits[2].instance_variable_set(:@date, "2003-10-10")
#          prev_visits[3].instance_variable_set(:@date, "1998-04-10")
#          prev_visits[4].instance_variable_set(:@date, "1999-02-28")
     
  end

  def concept_id_var
     var = { 
         "wt_id" => Concept.find_by_name("weight").id, 
         "ht_id" => Concept.find_by_name("height").id,
         "outcome_id" => Concept.find_by_name("Outcome status").id,
         "ARVReg_id" => Concept.find_by_name("ARV regimen").id,
         "Amb_id" => Concept.find_by_name("Is Ambulatory").id,
         "Wrk_Sch_id" => Concept.find_by_name("Is at work/school").id,
         "ARVRem_id" => Concept.find_by_name("Number of ARV tablets remaining").id,
         "ARVDisp_id" => Concept.find_by_name("Number of ARV tablets dispensed").id,
         "onCPT_id" => Concept.find_by_name("Is on CPT").id,
         "CPTNum_id" => Concept.find_by_name("Number of CPT tablets dispensed").id,
         "CD4_done_id" => Concept.find_by_name("CD4 count done").id,
         "CD4Ct_id" => Concept.find_by_name("CD4 count").id,
         "CD4Percent_id" => Concept.find_by_name("CD4 percentage").id
       }
  end

end
