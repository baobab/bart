class LabPanel < OpenMRS
	  set_table_name "map_lab_panel"
  
  def self.test_name(test_types=nil)
    return self.find(:all,:conditions=>["rec_id IN (?)",test_types],:group=>"rec_id").collect{|n|n.short_name} rescue nil
  end
  
  def self.get_test_type(test_name)
    panel_id = self.find(:first,:conditions=>["short_name=?",test_name]).rec_id rescue nil
    return LabTestType.find(:all,:conditions=>["Panel_ID=?",panel_id]).collect{|types|types.TestType} rescue nil
  end

 end 
