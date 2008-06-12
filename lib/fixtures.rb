# Based on the ar_fixtures plugin
class ActiveRecord::Base
  cattr_accessor :fixture_names
  
  def self.set_fixture_name(*args) 
    self.fixture_names ||= Hash.new
    self.fixture_names[self.table_name] = args
  end

  def self.to_fixtures(path=nil)
    path ||= File.expand_path("db/defaults/#{table_name}.yml", RAILS_ROOT)
    path = File.join(path, "#{table_name}.yml") if File.directory?(path)
    puts "Creating fixtures: #{path} (composite: #{self.composite? rescue false})"
    file = File.open(path, "w")
    file.puts(self.find(:all).inject({}) { |hash, record| 
      hash.merge(record.to_fixture_name => record.attributes) 
    }.to_yaml(:SortKeys => true))
    file.close
  end
  
  def to_fixture_name  
    n = self.fixture_names[self.class.table_name].map{|att| "#{self.instance_eval(att)}"}.join("_") unless self.fixture_names[self.class.table_name].blank?
    n ||= "#{self.class.table_name.singularize}_#{'%05i' % to_param rescue to_param}"
    n = n.downcase
    n = n.gsub(/(\s|-|\/)/, '_')
    n = n.gsub(/__/, '_')
    n = n.gsub(/[^a-z0-9_]/, '')     
  end
end    
