class CreateValidationRules < ActiveRecord::Migration
   def self.up                                                                   
    create_table :validation_rules do |t|                                       
      t.string  :expr                                                           
      t.string  :desc                                                           
      t.integer :type_id # 1: cohort report; 2: data quality                    
                                                                                
      t.timestamps                                                              
    end                                                                         
                                                                                
  end                                                                           
                                                                                
  def self.down                                                                 
    drop_table :validation_rules                                                
  end
end
