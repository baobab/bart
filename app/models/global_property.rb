class GlobalProperty < OpenMRS
  set_table_name "global_property"
  set_primary_key "id"


  @@global_property_hash_by_property = Hash.new
  @@global_property_hash_by_id = Hash.new
  self.find(:all).each{|global_property|
    @@global_property_hash_by_property[global_property.property.downcase] = global_property
    @@global_property_hash_by_id[global_property.id] = global_property
  }

  def self.find_by_property(property)
    return @@global_property_hash_by_property[property.downcase] || super
  end

  def to_s
    return "#{property}: #{property_value}"
  end  
end


### Original SQL Definition for global_property #### 
#  `id` int(11) NOT NULL auto_increment,
#  `property` varchar(255) default NULL,
#  `property_value` varchar(255) default NULL,
