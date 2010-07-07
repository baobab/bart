class TableLabResult < OpenMRS
  set_table_name "tblLabResults"

  def self.lab_results
    self.find(:all,:conditions =>["TestResult IS NOT NULL"])
  end
end
