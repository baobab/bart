class AddCategoryColumnToPatientHistoricalRegimens < ActiveRecord::Migration
   def self.up                                                                   
    add_column :patient_historical_regimens, :category, :string, :limit => 2              
  end                                                                           
                                                                                
  def self.down                                                                 
    remove_column :patient_historical_regimens, :category                                   
  end   
end
