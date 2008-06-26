require File.dirname(__FILE__) + '/../spec_helper'

describe Report do
  # You can move this to spec_helper.rb
  set_fixture_class :report => Report
  fixtures :report

  sample({
  })

  it "should be valid" do
    #report = create_sample(Report)
    (regimen_name, min_weight, max_weight, drug, frequency, units) = ['Stavudine Lamivudine', 0, 9, 'Stavudine Lamivudine', 'Morning', 1]
    regimen = Regimen.new(regimen_name, min_weight, max_weight, drug, frequency, units)
    regimen.regimen.should == regimen_name
    regimen.min_weight.should == min_weight
    regimen.max_weight.should == max_weight
    regimen.drug.should == drug
    regimen.frequency.should == frequency
    regimen.units.should == units
  end
  
end
