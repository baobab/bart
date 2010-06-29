class LabController < ApplicationController
  def test
    #render :text => "Test" ; return
    @available_test = LabTestType.available_test
  end

  def test_name
    render :text => LabTestType.find(:all,
      :conditions =>["REPLACE(TestName,'_',' ') LIKE ?","%#{params[:name]}%"],:order =>"TestName ASC").map{
      |test|"<li id=#{test.TestType}>#{test.TestName.gsub('_',' ')}</li>"
    } 
    return
  end
  
  def create
    test_type = LabTestType.find(:first,
      :conditions =>["TestName = ? OR TestName = ?",params[:name].to_s,params[:name].to_s.gsub(" ","_")])
    date = "#{params[:test_year]}-#{params[:test_month]}-#{params[:test_day]}".to_date rescue nil
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
    test_value = params[:test_value].to_s.match(/[0-9]+/)[0]

    patient = Patient.find(session[:patient_id])
    available_test_type = LabTestType.find(:all,:conditions=>["TestType IN (?)",test_type.TestType]).collect{|n|n.Panel_ID}

    lab_test_table = LabTestTable.new()
    lab_test_table.TestOrdered = LabPanel.test_name(available_test_type)[0]
    lab_test_table.Pat_ID = patient.national_id
    lab_test_table.OrderDate = date
    lab_test_table.OrderTime = Time.now().strftime("%H:%M:%S")
    lab_test_table.OrderedBy = User.current_user.id
    lab_test_table.Location = Location.current_location.name
    lab_test_table.save

    #to be refactored...
    accession_num = LabTestTable.find(:first,
        :conditions =>["Pat_ID=? AND OrderDate=? AND OrderTime = ? AND OrderedBy=?",
        lab_test_table.Pat_ID,lab_test_table.OrderDate,lab_test_table.OrderTime,lab_test_table.OrderedBy]).AccessionNum
    #.................

    lab_sample = LabSample.new()
    lab_sample.AccessionNum = accession_num
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

    #to be refactored...
    sample_id = LabSample.find(:first,
        :conditions =>["AccessionNum = ?",accession_num]).Sample_ID
    #.................

    lab_parameter = LabParameter.new()
    lab_parameter.Sample_ID = sample_id
    lab_parameter.TESTTYPE =  test_type.TestType
    lab_parameter.TESTVALUE = test_value
    lab_parameter.TimeStamp = Time.now()
    lab_parameter.Range = test_modifier
    lab_parameter.save

    redirect_to :controller => "patient", :action => "lab_menu"
    return
  end

end
