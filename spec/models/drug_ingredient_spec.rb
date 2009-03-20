require File.dirname(__FILE__) + '/../spec_helper'

describe DrugIngredient do

  sample({
    :concept_id => 1,
    :ingredient_id => 1,
  })

  it "should be valid" do
    drug_ingredient = create_sample(DrugIngredient)
    drug_ingredient.should be_valid
  end

  it "should display fixture name" do
    DrugIngredient.find_by_ingredient_id(378).to_fixture_name == "stavudine_lamivudine_nevirapine_contains_nevirapine"
  end

end
