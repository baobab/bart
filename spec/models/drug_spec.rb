require File.dirname(__FILE__) + '/../spec_helper'

describe Drug do
  fixtures :drug

  sample({
    :name => "Stavudine 6 Lamivudine 30 Nevirapine 50",
    :concept_id => 337,
    :dosage_form => nil,
    :date_created => "2008-05-22 12:01:01 +02:00".to_time,
    :creator => 5,
    :therapy_class => nil,
    :route => "PO",
    :dose_strength => nil,
    :units => "mg",
    :drug_id => 56,
    :combination => true,
    :minimum_dose => nil, 
    :daily_mg_per_kg => nil,
    :inn => nil,
    :shelf_life => nil,
    :maximum_dose => nil,
  })

  it "should be valid" do
    drug = create_sample(Drug)
    drug.should be_valid
  end

  it "should find drug by name" do
    Drug.find_by_name("Stavudine 6 Lamivudine 30 Nevirapine 50").should == drug(:drug_00056)
  end

  it "should display type of drug" do
    drug(:drug_00056).type.to_s.should == "Stavudine Lamivudine Nevirapine Regimen"
  end

  it "should display if drug is an arv" do
    drug(:drug_00056).arv?.should == true
  end

  it "should display drug abbreviation" do
    drug(:drug_00056).to_abbreviation.split.to_s.should == "Oth:"
  end  

  it "should display drug short name" do
    drug(:drug_00056).short_name.should == "d4T 3TC NVP"
  end  

















end
