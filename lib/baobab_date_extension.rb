module Baobab
  module Extensions

    def quarter
      (month.to_f/3).ceil
    end

    def start_of_quarter
      first_month_in_quarter = month
      first_month_in_quarter -= 1 while((first_month_in_quarter-1) % 3 != 0)
      DateTime.new(year,first_month_in_quarter)
    end

    def start_next_quarter
      current_year = year
      next_quarter_month = month + 3
      if next_quarter_month > 12
        next_quarter_month = 12 - next_quarter_month  
        current_year += 1
      end
      return DateTime.new(current_year,next_quarter_month).start_of_quarter
    end

  end
end
