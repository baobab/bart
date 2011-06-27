require 'migrator'
#require 'spec/spec_helper'
require 'config/environment'

describe Migrator do
  before(:each) do
    @migrator = Migrator.new(5)
  end

  it "should get field headers" do
    @migrator.default_fields.should_not be_nil
    @migrator.headers.should_not be_nil
  end

  it "should get encounter row" do
    encounter = Encounter.find_by_encounter_type(@migrator.type.id)
    @migrator.row(encounter).should_not be_nil
  end

  it "should create the CSV file" do
    file = '/tmp/' + @migrator.type.name.gsub(' ', '_') + '.csv'
    @migrator.to_csv(file)
    File.exist?(file).should be_true
  end

  it "should get observation's value" do
    o = Observation.new(:concept_id => 1, :value_coded => 3,
                        :value_numeric => 7)
    @migrator.obs_value(o).should == 3
    o.value_coded = nil
    o.value_numeric = 7
    @migrator.obs_value(o).should == 7
  end
end

