class LabController < ApplicationController
  def test
    @available_test = LabTestType.available_test
    unless session[:patient_program].blank?
      @lab_test = ['']
      LabTestType.find(:all,
      :conditions =>["REPLACE(TestName,'_',' ') LIKE ?","%#{params[:name]}%"],
      :order =>"TestName ASC").map{|test|
        @lab_test << [test.TestName.gsub('_',' '),test.TestName]
      }
      @patient_id = params[:id]
      render(:layout => false)
    end
  end

  def test_name
    render :text => LabTestType.find(:all,
      :conditions =>["REPLACE(TestName,'_',' ') LIKE ?","%#{params[:name]}%"],:order =>"TestName ASC").map{
      |test|"<li id=#{test.TestType}>#{test.TestName.gsub('_',' ')}</li>"
    } 
    return
  end
  
  def create
    if session[:patient_program].blank?
      patient = Patient.find(session[:patient_id]) 
      test_type = LabTestType.find(:first,
        :conditions =>["TestName = ? OR TestName = ?",params[:name].to_s,params[:name].to_s.gsub(" ","_")])
      date = "#{params[:test_year]}-#{params[:test_month]}-#{params[:test_day]}".to_date rescue nil
    else
      test_type = LabTestType.find(:first,
        :conditions =>["TestName = ?",params[:name].to_s])
      if params[:date_available] == "Yes"
        date = "#{params[:test_date]['(1i)']}-#{params[:test_date]['(2i)']}-#{params[:test_date]['(3i)']}".to_date rescue nil
      else
        date = "1900-01-01".to_date
      end   
      params[:test_value] = params[:mod_cont] + params[:test_value].to_s
      patient = Patient.find(params[:id]) 
    end

    if date.blank?
      if params[:test_year] == "Unknown"
        date = "1900-01-01".to_date
      elsif params[:test_month] == "Unknown"
        date = "#{params[:test_year]}-07-01".to_date
      end
    end  
 
    if test_type.blank?
      render :text => "#{test_type.TestType} ---- #{params[:name]}" ; return
    end

    test_modifier = params[:test_value].to_s.match(/=|>|</)[0]
    test_value = params[:test_value].to_s.gsub('>','').gsub('<','').gsub('=','')
    available_test_type = LabTestType.find(:all,:conditions=>["TestType IN (?)",test_type.TestType]).collect{|n|n.Panel_ID}

    lab_test_table = LabTestTable.new()
    lab_test_table.TestOrdered = LabPanel.test_name(available_test_type)[0]
    lab_test_table.Pat_ID = patient.national_id
    lab_test_table.OrderDate = date
    lab_test_table.OrderTime = Time.now().strftime("%H:%M:%S")
    lab_test_table.OrderedBy = User.current_user.id
    lab_test_table.Location = Location.current_location.name
    lab_test_table.save

    # try
    # lab_test_table.reload
    # sleep(1) while ltt.AccessionNum <= LabTestTable.last.AccessionNum
    lab_test_table.reload

    lab_sample = LabSample.new()
    lab_sample.AccessionNum = lab_test_table.AccessionNum
    lab_sample.USERID = User.current_user.id
    lab_sample.TESTDATE = date 
    lab_sample.PATIENTID = patient.national_id
    lab_sample.DATE = date
    lab_sample.TIME = Time.now().strftime("%H:%M:%S")
    lab_sample.SOURCE = Location.current_location.id
    lab_sample.DeleteYN = 0
    lab_sample.Attribute = "pass"
    lab_sample.TimeStamp = Time.now() 
    lab_sample.save

    lab_sample.reload

    lab_parameter = LabParameter.new()
    lab_parameter.Sample_ID = lab_sample.Sample_ID
    lab_parameter.TESTTYPE =  test_type.TestType
    lab_parameter.TESTVALUE = test_value
    lab_parameter.TimeStamp = Time.now()
    lab_parameter.Range = test_modifier
    lab_parameter.save
    
    if session[:patient_program] == "TB"
      redirect_to :controller => "patient", :action => "tb_card" ,:id => patient.id
    elsif session[:patient_program] == "HIV"
      redirect_to :controller => "patient", :action => "tb_card" ,:id => patient.id
    else
      redirect_to :controller => "patient", :action => "lab_menu"
    end
    return
  end

end
