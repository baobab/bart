class TableVisit 

  def self.art_visits(patient_id = nil)
    attr_accessor :date, :weight, :height, :anemia, :apptdate, :temp, :side_eff, :treatment_change, :total_pills_left,:arv_supply,:cpt_time_period, :guardian_present, :art_continuation,:drug_dispensed

    visits = {}
    side_eff = TableSideEffect.find(:all,:conditions => ["PatientID=?",patient_id])

    if side_eff
      side_eff.each do |eff|
        next if eff.ApptDate.blank?
        visits[eff.ApptDate.to_date] = self.new()
        visits[eff.ApptDate.to_date].guardian_present = "Yes" if eff.GuardianAtAppt == 1
        visits[eff.ApptDate.to_date].art_continuation = "Stop" if eff.ARVContinuation == 2
      
        visits[eff.ApptDate.to_date].weight = eff.WeightFU
        visits[eff.ApptDate.to_date].height = eff.HeightFU
        visits[eff.ApptDate.to_date].temp = eff.TempFU
        visits[eff.ApptDate.to_date].treatment_change = TableList.arv_regimen(eff.TreatmentChange) 
        visits[eff.ApptDate.to_date].drug_dispensed = TableList.arv_drug_dispensed(eff.TreatmentChange) 
        visits[eff.ApptDate.to_date].arv_supply = self.time_period(eff.ARVSupply)
        visits[eff.ApptDate.to_date].cpt_time_period = self.time_period(eff.CTXSupply)
=begin
        if visits[eff.ApptDate.to_date].treatment_change and visits[eff.ApptDate.to_date].arv_supply.blank?
          visits[eff.ApptDate.to_date].arv_supply = "1 month"
        end  
=end       
        total_pills_left = []

        total_pills_left << "#{self.drug_full_name('d4T')}:#{eff.d4TLeft}" if eff.d4TLeft
        total_pills_left << "#{self.drug_full_name('TC')}:#{eff.TCLeft}" if eff.TCLeft
        total_pills_left << "#{self.drug_full_name('NVP')}:#{eff.NVPLeft}" if eff.NVPLeft 
        total_pills_left << "#{self.drug_full_name('AZT')}:#{eff.AZTLeft}" if eff.AZTLeft 
        total_pills_left << "#{self.drug_full_name('EFV')}:#{eff.EFVLeft}" if eff.EFVLeft 
        total_pills_left << "#{self.drug_full_name('TDF')}:#{eff.TDFLeft}" if eff.TDFLeft 
        total_pills_left << "#{self.drug_full_name('LVPr')}:#{eff.LVPrLeft}" if eff.LVPrLeft 
        total_pills_left << "#{self.drug_full_name('ddI')}:#{eff.ddILeft}" if eff.ddILeft 
        total_pills_left << "#{self.drug_full_name('ABC')}:#{eff.ABCLeft}" if eff.ABCLeft 
        total_pills_left << "#{self.drug_full_name('T30')}:#{eff.T30Left}" if eff.T30Left
        total_pills_left << "#{self.drug_full_name('T40')}:#{eff.T40Left}" if eff.T40Left 
        visits[eff.ApptDate.to_date].total_pills_left = total_pills_left 

        side_effects = []

        if eff.ARVSideFX  == 1
          side_effects << "Anaemia" if eff.Anemia == -1
          side_effects << "Hepatitis" if eff.Hepatitis == -1
          side_effects << "Lactic acidosis" if eff.LacticAcidosis == -1
          side_effects << "Lipodystrophy" if eff.Lipodystrophy == -1
          side_effects << "Peripheral neuropathy" if eff.PeripheralNeuropathy == -1
          side_effects << "Pancreatitis" if eff.Pancreatitis == -1
          side_effects << "Skin rash" if eff.Rash == -1
          side_effects << "Other" if eff.OtherSideFX == -1
          visits[eff.ApptDate.to_date].side_eff = side_effects
        end
      end
    end
    visits
  end
  
  def self.drug_full_name(short_name = nil)
    case short_name
      #return drug id
      when "d4T"
        return 29 
      when "TC"
       return 14
      when "NVP"
       return 9
      when "AZT"
       return 27
      when "EFV"
       return 7
      when "TDF"
      when "LVPr"
      when "ddI"
       return 49
      when "ABC"
       return 10
      when "T30"
       return 5
      when "T40"
       return 6
    end
  end

  def self.time_period(weeks = nil)
    return if weeks.blank?
    return nil if weeks < 1
    return "1 week" if weeks == 1
    return "#{weeks} weeks" if weeks < 4
    month =  weeks/4 
    return "#{month} month" if month == 1
    return "#{month} months" 
  end

  def self.tb_visits(patient_id = nil)
    attr_accessor :art_status, :start_date, :end_date, :regimen, :sputum_count, :cpt, :outcome, 
    :encounter_datetime,:patient_id,:tb_type,:episode_type
    tb_obs = TableTb.find(:all,:conditions => ["PatientID=?",patient_id])
    visits = {}

    tb_obs.each do |tb|
      tb_visit_dates = []
      sputum_count = {}
      tb_visit_dates << tb.TbTreatStart.to_date rescue nil

      if tb.Sputum2
        tb_visit_dates << tb_visit_dates[0] + 1.month
        sputum_count[tb_visit_dates[0] + 1.month] = tb.Sputum2
      end  
      if tb.Sputum3
        tb_visit_dates << tb_visit_dates[0] + 2.month
        sputum_count[tb_visit_dates[0] + 2.month] = tb.Sputum3
      end  
      if tb.Sputum5
        tb_visit_dates << tb_visit_dates[0] + 3.month
        sputum_count[tb_visit_dates[0] + 3.month] = tb.Sputum5
      end 
      sputum_count[tb_visit_dates[0]] = tb.Sputum0 unless  tb.Sputum0.blank?
      tb_end_date = tb.TbTreatEnd.to_date rescue nil

      count = 0 
      tb_visit_dates.each do |visit_date|  
        visits["#{tb.TbID}::#{visit_date}"] = self.new() 
        visits["#{tb.TbID}::#{visit_date}"].sputum_count = sputum_count[visit_date]
        if count == 0
          visits["#{tb.TbID}::#{visit_date}"].art_status = TableList.art_status(tb.ARTStatus)
          visits["#{tb.TbID}::#{visit_date}"].start_date = tb.TbTreatStart.to_time rescue nil
          visits["#{tb.TbID}::#{visit_date}"].regimen = TableList.tb_regimen(tb.Regimen)
          visits["#{tb.TbID}::#{visit_date}"].cpt = tb.CPT
          visits["#{tb.TbID}::#{visit_date}"].episode_type = TableList.tb_episode_type(tb.EpisodeType)
          visits["#{tb.TbID}::#{visit_date}"].tb_type = TableList.tb_type(tb.TbType)
          visits["#{tb.TbID}::#{visit_date}"].patient_id = patient_id
          if tb_end_date
            visits["#{tb.TbID}::#{tb_end_date}"] = self.new() 
            visits["#{tb.TbID}::#{tb_end_date}"].outcome = TableList.tb_outcome(tb.Outcome)
            visits["#{tb.TbID}::#{tb_end_date}"].end_date = tb.TbTreatEnd.to_time rescue nil
          else
            visits["#{tb.TbID}::#{visit_date}"].end_date = tb.TbTreatEnd.to_time rescue nil
            visits["#{tb.TbID}::#{visit_date}"].outcome = TableList.tb_outcome(tb.Outcome)
          end
        end
        count+=1
      end
    end
    visits
  end

end 
