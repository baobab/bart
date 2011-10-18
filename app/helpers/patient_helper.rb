module PatientHelper

  def chart(next_appointment_date)
    chart = ''
    1.upto(12).each do | number |
      start_date = "01-#{number}-#{next_appointment_date.year}".to_date
      end_date = (start_date + 1.month) - 1.day 
      chart+=<<EOF
<table id="#{end_date.strftime('%B')}" class="months">
<caption class = 'title'>#{end_date.strftime('%B')}</caption>
<tr>
  <th>Sunday</th>
  <th>Monday</th>
  <th>Tuesday</th>
  <th>Wednesday</th>
  <th>Thursday</th>
  <th>Friday</th>
  <th>Saturday</th>
</tr>
EOF
 
      while (start_date <= end_date) 
        sunday = nil ; monday = nil ; tuesday = nil ; wednesday = nil
        thursday = nil ; friday = nil ; saturday = nil
        case start_date.strftime('%A')
          when 'Monday'
            monday = start_date.day  
          when 'Tuesday'  
            tuesday = start_date.day  
          when 'Wednesday'  
            wednesday = start_date.day  
          when 'Thursday'  
            thursday = start_date.day  
          when 'Friday'  
            friday = start_date.day  
          when 'Saturday'  
            saturday = start_date.day  
          when 'Sunday'  
            sunday = start_date.day  
        end

        if monday
          tuesday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date) 
          wednesday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          thursday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          friday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          saturday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
        elsif tuesday
          wednesday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          thursday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          friday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          saturday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
        elsif wednesday
          thursday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          friday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          saturday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
        elsif thursday
          friday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          saturday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
        elsif friday
          saturday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
        elsif sunday
          monday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          tuesday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date) 
          wednesday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          thursday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          friday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
          saturday = (start_date+= 1.day).day if ((start_date + 1.day) <= end_date)
        end   

        sunday_str = "#{sunday}-#{start_date.strftime('%m-%Y')}".to_date rescue nil
        monday_str = "#{monday}-#{start_date.strftime('%m-%Y')}".to_date rescue nil
        tuesda_str = "#{tuesday}-#{start_date.strftime('%m-%Y')}".to_date rescue nil
        wednesday_str = "#{wednesday}-#{start_date.strftime('%m-%Y')}".to_date rescue nil
        thursday_str = "#{thursday}-#{start_date.strftime('%m-%Y')}".to_date rescue nil
        friday_str = "#{friday}-#{start_date.strftime('%m-%Y')}".to_date rescue nil
        saturday_str = "#{saturday}-#{start_date.strftime('%m-%Y')}".to_date rescue nil

        chart+=<<EOF
<tr>
  <td class='dates' id = '#{sunday_str}' onmousedown="addDate('#{sunday_str}')">#{sunday}</td>
  <td class='dates' id = '#{monday_str}' onmousedown="addDate('#{monday_str}')">#{monday}</td>
  <td class='dates' id = '#{tuesda_str}' onmousedown="addDate('#{tuesda_str}')">#{tuesday}</td>
  <td class='dates' id = '#{wednesday_str}' onmousedown="addDate('#{wednesday_str}')">#{wednesday}</td>
  <td class='dates' id = '#{thursday_str}' onmousedown="addDate('#{thursday_str}')">#{thursday}</td>
  <td class='dates' id = '#{friday_str}' onmousedown="addDate('#{friday_str}')">#{friday}</td>
  <td class='dates' id = '#{saturday_str}' onmousedown="addDate('#{saturday_str}')">#{saturday}</td>
</tr>
EOF
        start_date+= 1.day
      end
    end
    chart+='</table>'
    container=<<EOF
<div class = "container">
#{chart}
</div><br />
EOF
    container
  end

  def calender(next_appointment_date)
    content = ''
    content+= chart(next_appointment_date.to_date)
  end

end
