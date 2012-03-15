  function daysInMonth(month,year) {
    var m = [31,28,31,30,31,30,31,31,30,31,30,31];
    if (month != 2) return m[month - 1];
    if (year%4 != 0) return m[1];
    if (year%100 == 0 && year%400 != 0) return m[1];
    return m[1] + 1;
  } 

  function currMonth(month_num) {                                            
    var month = new Array(12);                                                    
    month[0]="January";                                                         
    month[1]="February";                                                        
    month[2]="March";                                                           
    month[3]="April";                                                           
    month[4]="May";                                                             
    month[5]="June";                                                            
    month[6]="July";                                                            
    month[7]="August";                                                          
    month[8]="September";                                                       
    month[9]="October";                                                         
    month[10]="November";                                                       
    month[11]="December";                                                       
                                                                                
    return month[month_num];                                                    
  }

   function chart(nextAppointmentDate) {
    var chart = ''
    var container = "<div class = 'container'>\n"
    var number = 1
    while (number < 13) {
      var startDate = number + "/1/" + nextAppointmentDate.getFullYear();
      startDate = new Date(startDate);
      var daysIn = daysInMonth((startDate.getMonth() + 1) , startDate.getFullYear());
      var endDate = number + "/" + daysIn + "/" + nextAppointmentDate.getFullYear();
      number++;
      endDate = new Date(endDate);

      chart+="<table id='" + currMonth(endDate.getMonth()) + "' class='months'>";
      chart+="\n<caption class = 'title'>" + currMonth(endDate.getMonth()) + "</caption>"
      chart+="\n<tr>\n<th>Sunday</th>\n<th>Monday</th>\n<th>Tuesday</th>\n<th>Wednesday</th>"
      chart+="\n<th>Thursday</th>\n<th>Friday</th>\n<th>Saturday</th>\n</tr>"
 
      while (startDate <= endDate) { 
        var sunday = '' ; var monday = '' ; var tuesday = '';
        var wednesday = '' ; var thursday = ''; 
        var friday = '' ; var saturday = '';

        var day = startDate.getDay();
        var wkDays = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"];
        day = wkDays[day];

        if (day == 'Monday') {
          monday = startDate.getDate(); 
        }else if (day == 'Tuesday') {
          tuesday = startDate.getDate();  
        }else if (day == 'Wednesday') {  
          wednesday = startDate.getDate();  
        }else if (day == 'Thursday') {  
          thursday = startDate.getDate();  
        }else if (day == 'Friday') { 
          friday = startDate.getDate();  
        }else if (day == 'Saturday') {  
          saturday = startDate.getDate();  
        }else if (day == 'Sunday') {  
          sunday = startDate.getDate();  
        }

        try {

        if (monday) {
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            tuesday = (new Date(startDate.getMonth + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            wednesday = (new Date(startDate.getMonth + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            thursday = (new Date(startDate.getMonth + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            friday = (new Date(startDate.getMonth + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            saturday = (new Date(startDate.getMonth + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
        } else if (tuesday) {
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            wednesday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            thursday = (new Date((startDate.getMonth() +1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))  
          }  
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            friday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }  
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            saturday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
        } else if (wednesday) {
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            thursday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            friday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            saturday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
        } else if (thursday) {
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            friday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            saturday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
        } else if (friday) {
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            saturday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
        /*} else if (saturday) {
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            sunday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }*/
        } else if (sunday) {
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            monday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            tuesday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            wednesday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            thursday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            friday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
          if (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()) <= endDate) {
            saturday = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear())).getDate()
            startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
          }
        }   

        }catch(e) {}
    
        try{
          sunday_str = new Date((startDate.getMonth() + 1) + "/" + sunday + "/" + startDate.getFullYear())
          sunday_str = dateFormat(sunday_str,"yyyy-mm-dd");
        }catch(e) {sunday_str = ''}

        try{
          monday_str = new Date((startDate.getMonth() + 1) + "/" + monday + "/" + startDate.getFullYear())
          monday_str = dateFormat(monday_str,"yyyy-mm-dd");
        }catch(e) {monday_str = ''}

        try{
          tuesday_str = new Date((startDate.getMonth() + 1) + "/" + tuesday + "/" + startDate.getFullYear())
          tuesday_str = dateFormat(tuesday_str,"yyyy-mm-dd");
        }catch(e) {tuesday_str = ''}

        try{
          wednesday_str = new Date((startDate.getMonth() + 1) + "/" + wednesday + "/" + startDate.getFullYear())
          wednesday_str = dateFormat(wednesday_str,"yyyy-mm-dd");
        }catch(e) {wednesday_str = ''}

        try{
          thursday_str = new Date((startDate.getMonth() + 1) + "/" + thursday + "/" + startDate.getFullYear())
          thursday_str = dateFormat(thursday_str,"yyyy-mm-dd");
        }catch(e) {thursday_str = ''}

        try{
          friday_str = new Date((startDate.getMonth() + 1) + "/" + friday + "/" + startDate.getFullYear())
          friday_str = dateFormat(friday_str,"yyyy-mm-dd");
        }catch(e) {friday_str = ''}

        try{
          saturday_str = new Date((startDate.getMonth() + 1) + "/" + saturday + "/" + startDate.getFullYear())
          saturday_str = dateFormat(saturday_str,"yyyy-mm-dd");
        }catch(e) {saturday_str = ''}


        chart+="\n<tr>"
        chart+= '\n<td onMouseDown="addDate(\''+sunday_str+'\');" class="dates" id="'+sunday_str+'">' +sunday+ "</td>";
        chart+= '\n<td onMouseDown="addDate(\''+monday_str+'\');" class="dates" id="'+monday_str+'">' +monday+ "</td>";
        chart+= '\n<td onMouseDown="addDate(\''+tuesday_str+'\');" class="dates" id="'+tuesday_str+'">' +tuesday+ "</td>";
        chart+= '\n<td onMouseDown="addDate(\''+wednesday_str+'\');" class="dates" id="'+wednesday_str+'">' +wednesday+ "</td>";
        chart+= '\n<td onMouseDown="addDate(\''+thursday_str+'\');" class="dates" id="'+thursday_str+'">' +thursday+ "</td>";
        chart+= '\n<td onMouseDown="addDate(\''+friday_str+'\');" class="dates" id="'+friday_str+'">' +friday+ "</td>";
        chart+= '\n<td onMouseDown="addDate(\''+saturday_str+'\');" class="dates" id="'+saturday_str+'">' +saturday+ "</td>";
        chart+="\n</tr>"

        try {
          startDate = (new Date((startDate.getMonth() + 1) + "/" + (startDate.getDate() + 1) + "/" + startDate.getFullYear()))
        }catch(e){
          break;  
        }
      }
        chart+='\n</table>'
    }
    container += chart + "\n</div><br />"
    return container
  }

