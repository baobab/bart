class TableTb < OpenMRS
  set_table_name "tTb"


  def self.all_tb_visits
    self.find(:all,:conditions => ["TbID IS NOT NULL"])
  end

end 
