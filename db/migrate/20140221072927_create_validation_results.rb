class CreateValidationResults < ActiveRecord::Migration
   def self.up                                                                   
    create_table :validation_results do |t|                                     
      t.integer :rule_id                                                        
      t.integer :failures      # number of patients who failed to satisfy rule  
      t.date    :date_checked  # date when this set of results were generated   
                                                                                
      t.timestamps                                                              
    end                                                                         
  end                                                                           
                                                                                
  def self.down                                                                 
    drop_table :validation_results                                              
  end
end
