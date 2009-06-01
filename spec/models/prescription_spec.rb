require File.dirname(__FILE__) + '/../spec_helper'

describe Prescription do
  # You can move this to spec_helper.rb

  before do
    (@amount_remaining_from_last_visit, @dose_amount, @drug, @frequency, @time_period) = [2, 30, 'Stavudine Lamivudine', 'Morning', '1 month']
    @prescription = Prescription.new(@drug, @frequency, @dose_amount, @time_period, @amount_remaining_from_last_visit)
  end

  it "should be valid" do
    prescription = @prescription
    prescription.dose_amount.should == @dose_amount
    prescription.drug.should == @drug
    prescription.frequency.should == @frequency
    prescription.time_period.should == @time_period
  end

end
