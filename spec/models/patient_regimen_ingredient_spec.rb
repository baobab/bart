require File.dirname(__FILE__) + '/../spec_helper'

describe PatientRegimenIngredient do
  fixtures :patient, :encounter, :encounter_type, :drug, :drug_ingredient, :drug_order, 
    :orders, :order_type, :concept, :concept_class, :concept_set, :obs

  # If this fails then you need to migrate the views into your test database
  it "should have the view" do
    PatientRegimenIngredient.find(:all).should_not be_empty
  end
  
  it "should list ingredients for all of the orders in an encounter"
  it "should associate ingredients with arv regimens"
  it "should not include ingredients that do not appear in regimens"
  it "should not include ingredients from voided orders"
  # worry about retired regimen concepts
end