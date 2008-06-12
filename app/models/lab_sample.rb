	class LabSample < OpenMRS
	  set_table_name "Lab_Sample"
    has_many :lab_parameter, :foreign_key => :sample_id 
   
    def self.cd4_trail(patient_identifier)
      sample_ids_and_test_dates = LabSample.find(:all,:conditions=>["PATIENTID IN (?)",patient_identifier]).collect{|sample|[sample.Sample_ID,sample.TESTDATE]} rescue nil
      return if sample_ids_and_test_dates.blank?

      cd4_trail_results = Hash.new()
      sample_ids_and_test_dates.each{|sample_id,test_dates|
        cd4_result = LabParameter.find_cd4_test_by_sample_id(sample_id)
        cd4_trail_results[test_dates] << cd4_result if !cd4_result.blank? and  !cd4_trail_results[test_dates].blank?
        cd4_trail_results[test_dates] = cd4_result unless cd4_result.blank? and  cd4_trail_results[test_dates].blank?
      }
      return cd4_trail_results unless cd4_trail_results.blank?
    end 

    def self.last_cd4_by_patient(patient_identifier = nil)
      return if patient_identifier.blank?
      cd4_test_type = LabTestType.find_by_TestName("CD4_count").TestType rescue nil
      return if cd4_test_type.blank?
      cd4_per_test_type = LabTestType.find_by_TestName("CD4_percent").TestType
      return LabSample.find_by_sql(["SELECT * FROM Lab_Sample join Lab_Parameter where Lab_Parameter.sample_id=Lab_Sample.sample_id and Lab_Sample.patientid IN (?) and (Lab_Parameter.TESTTYPE=? or Lab_Parameter.TESTTYPE=?) order by STR_TO_DATE(Lab_Sample.testdate,'%d-%b-%Y') desc",patient_identifier,cd4_per_test_type,cd4_test_type]).first rescue nil
    end
    
    def self.lab_trail(patient_identifier,test_types)
      sample_ids_and_test_dates = LabSample.find_by_sql(["SELECT * FROM Lab_Sample join Lab_Parameter where Lab_Sample.patientid IN (?) and Lab_Parameter.sample_id=Lab_Sample.sample_id and Lab_Parameter.testtype IN (?)",patient_identifier,test_types]).collect{|sample|[sample.Sample_ID,sample.TESTDATE]} rescue nil
      return if sample_ids_and_test_dates.blank?

      lab_trail_results = Hash.new()
      sample_ids_and_test_dates.each{|sample_id,test_dates|
        date = test_dates
        date="01-Jan-1900" if date.blank? || date == ""
        lab_result = LabParameter.find_lab_test_by_sample_id_test_type(sample_id,test_types)
        lab_trail_results[date] << lab_result if !lab_result and !lab_trail_results[date].blank?
        lab_trail_results[date] = lab_result unless lab_result.blank? and lab_trail_results[date].blank? 
      }
      return lab_trail_results
    end 
  end 
