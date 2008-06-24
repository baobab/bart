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
  
end
