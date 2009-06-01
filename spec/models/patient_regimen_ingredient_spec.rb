require File.dirname(__FILE__) + '/../spec_helper'

describe PatientRegimenIngredient do

  # If this fails then you need to migrate the views into your test database
  it "should have the view" do
    PatientRegimenIngredient.find(:all).should_not be_empty
  end

end
