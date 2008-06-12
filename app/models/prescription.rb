class Prescription
  def initialize(drug=nil, frequency=nil, dose_amount=nil, time_period=nil, amount_remaining_from_last_visit=0)
    @drug, @frequency, @dose_amount, @time_period, @amount_remaining_from_last_visit = drug, frequency, dose_amount, time_period, amount_remaining_from_last_visit
  end
  attr_accessor :drug, :frequency, :dose_amount, :time_period

  def to_s
    "#{drug.name} f:#{frequency} d:#{dose_amount} t:#{time_period}"
  end

  def quantity
    return 1 if frequency == "Once"
    
    time_period_days = nil
    self.time_period.downcase.match(/(\d+) (.*)/)
    time_amount = $1.to_i # number of weeks or months
    time_unit = $2  # weeks or months
    
    case time_unit
      when "day","days"
        time_period_days = 1
      when "week","weeks"
        time_period_days = 7
      when "month","months"
        time_period_days = 28
    end

    
    # Extra amount given should be 1 days worth for starter pack, 2 for others
    if time_period_days < 15
      buffer_time = 1 
    else
      buffer_time = 2
		end
    
    
    total_number_of_days = time_amount * time_period_days + buffer_time

    quantity = 0
      
    if frequency =~ /(morning|evening)/i
      quantity =  total_number_of_days * self.dose_amount.to_f * 1
    elsif frequency == "Weekly"
      raise "Weekly not completed yet"
      quantity = total_number_of_days * self.dose_amount.to_f / 7 #TODO
    end
    
    quantity -= @amount_remaining_from_last_visit
    quantity = 0 if quantity < 0

    return quantity
  end
end
