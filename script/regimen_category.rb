
def int
  file = File.open(File.join(RAILS_ROOT, "mapping_drug_regimen.csv"), File::RDONLY)
  file.readlines.map do |line|
    category = line.split(',').last.gsub('\n','').strip
    next if category == 'Non-Standard'
    drugs =  []
    (line.split(',')).map do |name|
      drug_name = name.gsub('"','').strip
      drug = Drug.find_by_name(drug_name) rescue nil
      next if drug.blank?
      drugs << drug
    end
   
    mapping = MappingDrugRegimen.new() 
    mapping.category = category
    mapping.save unless drugs.blank?

    drugs.map do |d|
      combination = DrugRegimenCombination.new()
      combination.combination = mapping.id
      combination.drug_id = d.id
      combination.save
      puts "#{category}.............. #{d.name}"
    end unless drugs.blank?
  end


end

int
