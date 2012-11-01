class CreateDrugRegimenCombinations < ActiveRecord::Migration
    def self.up                                                                   
ActiveRecord::Base.connection.execute <<EOF                                     
DROP TABLE IF EXISTS `drug_regimen_combinations`;                             
EOF
                                                                                
ActiveRecord::Base.connection.execute <<EOF                                     
CREATE TABLE `drug_regimen_combinations` (                                    
 `id` int(11) NOT NULL default 0,                               
 `combination` int(11) NOT NULL default 0,                                       
 `drug_id` int(11) NOT NULL default 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;                                         
EOF
                                                                                
 end                                                                            
                                                                                
                                                                                
  def self.down                                                                 
ActiveRecord::Base.connection.execute <<EOF                                     
DROP TABLE IF EXISTS `drug_regimen_combinations`;                             
EOF

  end 
end
