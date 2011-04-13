require File.dirname(__FILE__) + '/../spec_helper'

describe WeightHeightForAge do
  fixtures :weight_height_for_ages, :patient

  sample({
    :standard_high_weight => 12.3533897399902,
    :standard_low_height => 5.98912000656128,
    :age_in_months => 215,
    :standard_high_height => 5.98821020126343,
    :sex => 'Female',
    :median_weight => 56.6393890380859,
    :age_sex => "2151",
    :standard_low_weight => 7.29257011413574,
    :median_height => 163.65934753418
  })

  it "should be valid" do
    weight_height_for_age = create_sample(WeightHeightForAge)
    weight_height_for_age.should be_valid
  end

  it "should give patient height and weight values" do
    patient = Patient.new
    patient.birthdate = 212.months.ago.to_date
    patient.gender = 'Female'

    WeightHeightForAge.median_height(patient).should == 176.827987670898
    WeightHeightForAge.median_weight(patient).should == 68.7223434448242
   
    patient.birthdate = 10.years.ago
    patient.age_in_months.should == 121
    WeightHeightForAge.patient_height_weight_values(patient).median_height.should == 137.97639465332

  end

  it "should give patient median height" do
    patient = Patient.new
    patient.birthdate = 124.months.ago.to_date
    patient.gender = 'Male'
    WeightHeightForAge.median_height(patient).should == 140.948104858398
  end
 
  it "should give patient median weight" do
    patient = Patient.new
    patient.birthdate = 124.months.ago.to_date
    patient.gender = 'Male'
    WeightHeightForAge.median_weight(patient).should == 34.3516693115234
  end
 
end
