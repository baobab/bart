class CreateMappingDrugRegimens < ActiveRecord::Migration
    def self.up                                                                   
ActiveRecord::Base.connection.execute <<EOF
DROP TABLE IF EXISTS `mapping_drug_regimen`;                             
EOF
                                                                             
ActiveRecord::Base.connection.execute <<EOF                                     
CREATE TABLE `mapping_drug_regimen` (                                    
 `id` int(11) NOT NULL default 0,                               
 `category` varchar(2)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;                                         
EOF
                                                                                
 end                                                                            
                                                                                
                                                                                
  def self.down                                                                 
ActiveRecord::Base.connection.execute <<EOF                                     
DROP TABLE IF EXISTS `mapping_drug_regimen`;                             
EOF
                                                                          
  end 
end
