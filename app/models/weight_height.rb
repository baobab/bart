class WeightHeight
  @@min_height_male = Hash.new
  @@max_height_male = Hash.new
  @@min_weight_male = Hash.new
  @@max_weight_male = Hash.new
  @@min_height_female = Hash.new
  @@max_height_female = Hash.new
  @@min_weight_female = Hash.new
  @@max_weight_female = Hash.new
  
  File.open(File.join(RAILS_ROOT, "app/models/wtht_rangecheck.csv"), File::RDONLY).readlines.each{|line|
    (age_in_months,sex,low_height,high_height,low_weight,high_weight) = line.split(",").collect{|field|field.to_f}
    age_in_months = age_in_months.to_i
    if sex == 0
      @@min_height_male[age_in_months] = low_height
      @@max_height_male[age_in_months] = high_height
      @@min_weight_male[age_in_months] = low_weight
      @@max_weight_male[age_in_months] = high_weight
    else
      @@min_height_female[age_in_months] = low_height
      @@max_height_female[age_in_months] = high_height
      @@min_weight_female[age_in_months] = low_weight
      @@max_weight_female[age_in_months] = high_weight
    end
  }

  def WeightHeight.method_missing(method, sex, age_in_months)
    # if there is no matching age use the next lowest age
    age_in_months -= 1 while( eval("@@#{method}_#{sex.downcase}[#{age_in_months}]") == nil)
    eval "@@#{method}_#{sex.downcase}[#{age_in_months}]"
  end

end

