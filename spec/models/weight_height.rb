require File.dirname(__FILE__) + '/../spec_helper'

describe WeightHeight do
  sample({
    :age_in_months => 0,
    :sex => 0,
    :low_height => 41.33706283569336,
    :low_weight => 52.7718620300293,
    :high_height => 2.017090082168579,
    :high_weight => 3.7684199810028076
  })

  it "should be valid" do
#    weight_height = create_sample(WeightHeight)
#    weight_height.should be_valid
  end

  it "should return minimum height for patient" do
    # male
    patient = patient(:andreas)
    WeightHeight.min_height(patient.gender, patient.age_in_months).should == 151.0

    # female
    patient = patient(:tracy)
    patient.gender = 'Female'
    WeightHeight.min_height(patient.gender, patient.age_in_months).should == 142.0
  end

  it "should return minimum weight for patient" do
    # male
    patient = patient(:andreas)
    WeightHeight.min_weight(patient.gender, patient.age_in_months).should == 36.0

    # female
    patient = patient(:tracy)
    patient.gender = 'Female'
    WeightHeight.min_weight(patient.gender, patient.age_in_months).should == 28.0
  end
  
end
