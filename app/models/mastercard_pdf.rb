require 'base_pdf'
require 'fpdf_barcode_extension'

class MastercardPdf < BasePdf
  
  attr_accessor :patient
  attr_accessor :options
  
  def display(data = {}, options = {})
    options[:output_static] ||= true
    options[:output_header] ||= true
    options[:output_visits] ||= true
    self.options = options
    if data[:visits] && data[:visits].length > 0 && options[:output_visits]
      visit_dates = data[:visits].map {|v| v[:visit_date] }
      visit_dates.map(&:year).uniq.each {|year|
        self.output_static if options[:output_static]
        self.output_header_data(data, year)  if options[:output_header]
        data[:visits].each {|visit|
          self.output_visit_data(visit) if visit[:visit_date].year == year
        }  
      }  
    else
      self.output_static if options[:output_static]
      self.output_header_data(data, year)  if options[:output_header]
    end      
    self.Output(ENV['RAILS_ENV'] == 'test' ? ("#{RAILS_ROOT}/tmp/mastercard.pdf") : nil)
  end
  
  def Header 
    # This will print on every page
  end
  
  def Footer
    self.output_barcode(240, 180)
  end
  
protected

  def output_static()
    self.SetFont('Helvetica','',14)
    self.AddPage()
    self.SetLeftMargin(20)
    self.SetTopMargin(15)
    self.SetRightMargin(10)
    self.output_header(20, 15)
    self.output_name_and_vitals(20, 25)
    self.output_demographics(20, 35)
    self.output_guardian(20, 45)
    self.output_reason_for_starting(20, 55)
    self.output_sub_switch(20, 65)
    self.output_visits(20, 75)
    self.output_legend(20, 141)
  end

  def output_header(x, y)
    self.SetFont('Helvetica', 'B', 12)
    self.SetXY(x, y)
    self.MultiCell(119, 5, 'NEW PATIENT MASTER RECORD CARD FOR ARV [front]:', 0, 'L')    
    self.SetXY(x+120, y)
    self.MultiCell(50, 5, 'Unique ARV Number', 0, 'L')    
    self.SetXY(x+215, y)
    self.MultiCell(13, 5, 'Year', 0, 'L')    
    y += 4
    self.Line(x+163, y, x+214, y) # Arv number   
    self.Line(x+225, y, x+260, y) # Year   
  end

  def output_name_and_vitals(x, y)
    self.SetFont('Helvetica', '', 11)
    self.SetXY(x, y)
    self.MultiCell(15, 5, 'Name', 0, 'L')    
    self.SetXY(x+77, y)
    self.MultiCell(15, 5, 'Age', 0, 'L')    
    self.SetXY(x+99, y)
    self.MultiCell(15, 5, 'Sex', 0, 'L')    
    self.SetXY(x+121, y)
    self.MultiCell(30, 5, 'Initial Wt (Kg)', 0, 'L')    
    self.SetXY(x+166, y)
    self.MultiCell(30, 5, 'Initial Ht (cm)', 0, 'L')    
    self.SetXY(x+209, y)
    self.MultiCell(35, 5, 'Transfer-In (Y/N)', 0, 'L')    
    y += 4
    self.Line(x+11, y, x+77, y) # Name   
    self.Line(x+86, y, x+95, y) # Age   
    self.Line(x+107, y, x+115, y) # Sex    
    self.Line(x+146, y, x+161, y) # Initial Weight   
    self.Line(x+190, y, x+203, y) # Initial Height   
    self.Line(x+240, y, x+260, y) # Transfer In   
  end
  
  def output_demographics(x, y)
    self.SetFont('Helvetica', '', 11)
    self.SetXY(x, y)
    self.MultiCell(69, 5, 'Address (physical address and phone)', 0, 'L')    
    self.SetXY(x+197, y)
    self.MultiCell(49, 5, 'Follow-up agreement (Y/N)', 0, 'L')    
    y += 4
    self.Line(x+69, y, x+196, y) # Address
    self.Line(x+245, y, x+260, y) # Agrees to follow   
  end
  
  def output_guardian(x, y)
    self.SetFont('Helvetica', '', 11)
    self.SetXY(x, y)
    self.MultiCell(53, 5, 'Name of identifiable guardian', 0, 'L')    
    self.SetXY(x+134, y)
    self.MultiCell(63, 5, 'Date and place of positive HIV test', 0, 'L')    
    y += 4
    self.Line(x+52, y, x+134, y) # Guardian   
    self.Line(x+196, y, x+260, y) # Date and place of positive HIV test   
  end
  
  def output_reason_for_starting(x, y)
    self.SetFont('Helvetica', '', 11)
    self.SetXY(x, y)
    self.MultiCell(67, 5, 'Date of starting 1st line ARV regimen', 0, 'L')    
    self.SetXY(x+96, y)
    self.MultiCell(44, 5, 'Reason for ARV: Stage', 0, 'L')    
    self.SetXY(x+169, y)
    self.MultiCell(12, 5, '; PTB', 0, 'L')    
    self.SetXY(x+190, y)
    self.MultiCell(15, 5, '; EPTB', 0, 'L')    
    self.SetXY(x+211, y)
    self.MultiCell(10, 5, '; KS', 0, 'L')    
    self.SetXY(x+232, y)
    self.MultiCell(18, 5, '; PMTCT', 0, 'L')    
    y += 4
    self.Line(x+66, y, x+96, y) # Start date   
    self.Line(x+138, y, x+169, y) # Stage   
    self.Line(x+181, y, x+191, y) # PTB   
    self.Line(x+204, y, x+212, y) # EPTB   
    self.Line(x+220, y, x+233, y) # KS   
    self.Line(x+249, y, x+260, y) # PMTCT   
  end
  
  def output_sub_switch(x, y)
    self.SetFont('Helvetica', '', 11)
    self.SetXY(x, y)
    self.MultiCell(104, 5, 'Date of starting alternative 1st line ARV Regimen (specify)', 0, 'L')    
    self.SetXY(x+137, y)
    self.MultiCell(83, 5, 'Date of starting 2nd line ARV regimen (specify)', 0, 'L')      
    y += 4
    self.Line(x+102, y, x+136, y) # 1st line alternative   
    self.Line(x+219, y, x+260, y) # 2nd line   
  end

  def output_visits(x, y)
    w = 260
    h = 64
    self.Rect(x, y, w, h)
    self.Line(x+15, y, x+15, y+h)    
    self.Line(x+28, y, x+28, y+h)    
    self.Line(x+38, y, x+38, y+h)    
    self.Line(x+50, y, x+50, y+h)    
    self.Line(x+92, y, x+92, y+h)    
    self.Line(x+130, y, x+130, y+h)    
    self.Line(x+155, y, x+155, y+h)    
    self.Line(x+180, y, x+180, y+h)    
    self.Line(x+200, y, x+200, y+h)    
    self.Line(x+217, y, x+217, y+h)    
    self.Line(x+236, y, x+236, y+h)    
    self.Line(x+247, y, x+247, y+h)    

    self.Line(x+56, y+8, x+56, y+h)    
    self.Line(x+63, y+8, x+63, y+h)    
    self.Line(x+72, y+8, x+72, y+h)    
    self.Line(x+83, y+8, x+83, y+h)    
    self.Line(x+105, y+8, x+105, y+h)    
    self.Line(x+115, y+8, x+115, y+h)    
    self.Line(x+143, y+8, x+143, y+h)    
    self.Line(x+169, y+8, x+169, y+h)    
    self.Line(x+190, y+8, x+190, y+h)    
    self.Line(x+227, y+8, x+227, y+h)    

    self.Line(x+50, y+8, x+200, y+8)    
    self.Line(x+217, y+8, x+236, y+8)    

    (0..12).each {|i|
      self.Line(x, y+13+(i*4.25), x+w, y+13+(i*4.25))    
    }  

    self.SetFont('Helvetica', 'B', 11)
    self.SetXY(x, y)
    self.MultiCell(15, 12, 'Month', 0, 'C')    
    self.SetXY(x+15, y)
    self.MultiCell(13, 12, 'Date', 0, 'C')    
    self.SetXY(x+28, y+3)
    self.MultiCell(10, 3.5, "Wt\nKg", 0, 'C')    
    self.SetXY(x+38, y+3)
    self.MultiCell(12, 3.5, "Ht\ncm", 0, 'C')    
    self.SetXY(x+50, y)
    self.MultiCell(42, 8, "Outcome Status", 0, 'C')    
    self.SetXY(x+92, y)
    self.MultiCell(38, 8, "Of those alive", 0, 'C')    
    self.SetXY(x+130, y)
    self.MultiCell(25, 8, "Ambulatory", 0, 'C')    
    self.SetXY(x+155, y)
    self.MultiCell(26, 8, "Work/school", 0, 'C')    
    self.SetXY(x+180, y+0.7)
    self.MultiCell(20, 3.5, "Side effects", 0, 'C')    
    self.SetXY(x+200, y+0.7)
    self.MultiCell(17, 3.5, "No.\nPills in\nBottle", 0, 'C')    
    self.SetXY(x+217, y+0.7)
    self.MultiCell(19, 3.5, "ARV Given", 0, 'C')    
    self.SetXY(x+236, y)
    self.MultiCell(11, 8, "CPT", 0, 'C')    
    self.SetXY(x+247, y)
    self.MultiCell(13, 8, "Other", 0, 'C')    

    self.SetXY(x+50, y+8.2)
    self.MultiCell(6, 4, "A", 0, 'C')    
    self.SetXY(x+56, y+8.2)
    self.MultiCell(7, 4, "D", 0, 'C')    
    self.SetXY(x+63, y+8.2)
    self.MultiCell(11, 4, "DF", 0, 'C')    
    self.SetXY(x+72, y+8.2)
    self.MultiCell(11, 4, "Stop", 0, 'C')    
    self.SetXY(x+83, y+8.2)
    self.MultiCell(9, 4, "TO", 0, 'C')    
    self.SetXY(x+92, y+8.2)
    self.MultiCell(13, 4, "Start", 0, 'C')    
    self.SetXY(x+105, y+8.2)
    self.MultiCell(10, 4, "Sbs", 0, 'C')    
    self.SetXY(x+115, y+8.2)
    self.MultiCell(15, 4, "Switch", 0, 'C')    
    self.SetXY(x+130, y+8.2)
    self.MultiCell(13, 4, "Amb", 0, 'C')    
    self.SetXY(x+143, y+8.2)
    self.MultiCell(12, 4, "Bed", 0, 'C')    
    self.SetXY(x+155, y+8.2)
    self.MultiCell(14, 4, "Yes", 0, 'C')    
    self.SetXY(x+169, y+8.2)
    self.MultiCell(11, 4, "No", 0, 'C')    
    self.SetXY(x+180, y+8.2)
    self.MultiCell(10, 4, "Y", 0, 'C')    
    self.SetXY(x+190, y+8.2)
    self.MultiCell(10, 4, "N", 0, 'C')    
    self.SetXY(x+217, y+8.2)
    self.MultiCell(10, 4, "P", 0, 'C')    
    self.SetXY(x+227, y+8.2)
    self.MultiCell(9, 4, "G", 0, 'C')    

    self.SetFont('Helvetica', 'B', 10)
    ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'].each_with_index {|m,i|
      self.SetXY(x+1, y+13.2+(i*4.25))
      self.MultiCell(15, 4, m, 0, 'L')    
    }
  end
    
  def output_legend(x, y)
    self.SetFont('Helvetica', 'B', 11)
    self.SetXY(x, y)
    self.MultiCell(165, 4, 'Specify reason for ARV therapy (Stage III, Stage IV, CD4 < 200, PTB, EPTB, Transfer-in)', 0, 'L')    
    self.SetY(y+8)
    self.MultiCell(34, 4, 'Outcome status:', 0, 'L')      
    self.SetY(y+12)
    self.MultiCell(29, 4, 'Of those alive:', 0, 'L')     
    self.SetY(y+24)
    self.MultiCell(25, 4, 'Ambulatory:', 0, 'L')      
    self.SetY(y+28)
    self.MultiCell(26, 4, 'Work/school:', 0, 'L')     
    self.SetY(y+32)
    self.MultiCell(27, 4, 'Side effects:', 0, 'L')      
    self.SetY(y+36)
    self.MultiCell(34, 4, 'No.Pills in bottle:', 0, 'L')     
    self.SetY(y+40)
    self.MultiCell(71, 4, 'ARV given P=patient; G=guardian.', 0, 'L')    
    self.SetY(y+44)
    self.MultiCell(13, 4, 'CPT:', 0, 'L')    

    self.SetFont('Helvetica', '', 11)
    self.SetXY(x+34, y+8)
    self.MultiCell(220, 4, 'A=alive;  D=dead;  DF=defaulted and not seen for 3 months; Stop=stopped medication; TO=transferred out to another unit', 0, 'L')    
    self.SetXY(x+29, y+12)
    self.MultiCell(170, 4, 'Start=alive and on first line regimen; Sbs=alive and substituted to alternative first line regimen;', 0, 'L')    
    self.SetXY(x, y+16)
    self.MultiCell(162, 4, 'Switch=alive and switched to a second line regimen because of failure of first line regimen', 0, 'L')    
    self.SetXY(x+25, y+24)
    self.MultiCell(182, 4, 'Amb=able to walk to/at treatment unit and walks at home unaided;  Bed=most of time in bed at home', 0, 'L')    
    self.SetXY(x+26, y+28)
    self.MultiCell(220, 4, 'Yes=engaged in previous work / employment or at school; No=not engaged in previous work /employment or not at school', 0, 'L')    
    self.SetXY(x+25, y+32)
    self.MultiCell(235, 4, 'If Yes, specify PN=peripheral neuropathy; HP=hepatitis; SK=skin rash; LA=lactic acidosis; LD=lipodystrophy; AN=anaemia', 0, 'L')    
    self.SetXY(x+34, y+36)
    self.MultiCell(160, 4, 'if patient comes at 4 weeks count number of pills in bottle (8 pills or less = 95% adherent)', 0, 'L')    
    self.SetXY(x+65, y+40)
    self.MultiCell(115, 4, 'Indicate the number of tins of ART given to patient or guardian', 0, 'L')    
    self.SetXY(x+10, y+44)
    self.MultiCell(98, 4, 'indicate if patient on cotrimoxazole preventive therapy:', 0, 'L')      
    
    self.SetFont('Helvetica', 'B', 11)
    self.SetXY(x+107, y+44)
    self.MultiCell(52, 4, 'Blank column for remarks', 0, 'L')    
  end

  def output_barcode(x, y)
    # output the barcode
    self.EAN13(x, y, '123456789012')
  end

  def output_header_data(data, year) 
    x = 20
    y = 15
    self.write_data(x+163, y, x+214, "#{data[:arv_number]}")
    self.write_data(x+225, y, x+260, "#{year}")

    y = 25
    self.write_data(x+11, y, x+77, "#{data[:name]}")
    self.write_data(x+86, y, x+95, "#{data[:age]}") 
    self.write_data(x+107, y, x+115, "#{data[:sex]}")
    self.write_data(x+146, y, x+161, "#{data[:initial_weight]}")
    self.write_data(x+190, y, x+203, "#{data[:initial_height]}")
    self.write_data(x+240, y, x+260, "#{data[:transfer_in] ? 'Y' : 'N'}")

    y = 35
    self.write_data(x+69, y, x+196, "#{data[:address]}") 
    self.write_data(x+245, y, x+260, "#{data[:agrees_to_follow_up] ? 'Y' : 'N'}") 

    y = 45
    self.write_data(x+52, y, x+134, "#{data[:guardian_and_relation]}")
    self.write_data(x+196, y, x+260, "#{data[:date_and_place_positive_hiv_test]}")

    y = 55
    self.write_data(x+66, y, x+96, "#{data[:arv_start_date]}") 
    self.write_data(x+138, y, x+169, "#{data[:stage]}") 
    self.write_data(x+181, y, x+191, "#{data[:ptb] ? 'Y' : 'N'}")
    self.write_data(x+204, y, x+212, "#{data[:eptb] ? 'Y' : 'N'}")
    self.write_data(x+220, y, x+233, "#{data[:ks] ? 'Y' : 'N'}")
    self.write_data(x+249, y, x+260, "#{data[:pmtct] ? 'Y' : 'N'}")

    y = 65
    self.write_data(x+102, y, x+136, "#{data[:date_first_line_alternative]}") 
    self.write_data(x+219, y, x+260, "#{data[:date_second_line]}")     
  end
  
  def output_visit_data(data) 
    x = 20
    y = 88.25 + ((data[:visit_date].month-1) * 4.25)

    self.SetFont('Helvetica', '', 10)    
    self.write_data(x+15, y, x+28, "#{data[:visit_date].day}", 'C')    
    self.write_data(x+28, y, x+38, "#{data[:weight]}", 'C')    
    self.write_data(x+38, y, x+50, "#{data[:height]}", 'C')    
    case data[:outcome_status]
      when "A"
        self.write_data(x+50, y, x+56, "X", 'C')    
      when "D"
        self.write_data(x+56, y, x+63, "X", 'C')    
      when "DF"
        self.write_data(x+63, y, x+72, "X", 'C')    
      when "Stop"
        self.write_data(x+72, y, x+83, "X", 'C')    
      when "TO"
        self.write_data(x+83, y, x+92, "X", 'C')    
    end    

    case data[:start_sub_switch]
      when "Start"
        self.write_data(x+92, y, x+105, "X", 'C')    
      when "Sbs","Sub"
        self.write_data(x+105, y, x+115, "X", 'C')    
      when "Switch"
        self.write_data(x+115, y, x+130, "X", 'C')    
    end
    
    self.write_data(x+130, y, x+143, "#{'X' if data[:is_ambulatory]}", 'C')    
    self.write_data(x+143, y, x+155, "#{'X' if data[:is_ambulatory] === false}", 'C')    
    self.write_data(x+155, y, x+169, "#{'X' if data[:is_work_school]}", 'C')    
    self.write_data(x+169, y, x+180, "#{'X' if data[:is_work_school] === false}", 'C')    
    self.write_data(x+180, y, x+190, "#{data[:side_effects].join(',') if data[:side_effects]}", 'C')    
    self.write_data(x+190, y, x+200, "#{'X' if data[:side_effects].blank?}", 'C')    
    self.write_data(x+200, y, x+217, "#{data[:total_number_of_pills]}", 'C')    
    self.write_data(x+217, y, x+227, "#{data[:number_pills_given] if data[:arv_receipient] == 'P'}", 'C')    
    self.write_data(x+227, y, x+236, "#{data[:number_pills_given] if data[:arv_receipient] == 'G'}", 'C')    
    self.write_data(x+236, y, x+247, "#{'X' if data[:cpt]}", 'C')    
    self.write_data(x+247, y, x+260, "#{data[:other]}", 'C')    
  end
  
  def write_data(x, y, x2, text, align = 'L')
    self.SetXY(x+1, y)
    self.MultiCell(x2-x, 4, text, 0, align)        
  end
end
