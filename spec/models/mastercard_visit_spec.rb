require File.dirname(__FILE__) + '/../spec_helper'

describe MastercardVisit do

  it "should be valid" do
    visit = MastercardVisit.new()
    visit.date = Time.now()
    visit.weight = 60.0 
    visit.height= 166.0
    visit.bmi = nil
    visit.outcome = nil
    visit.reg = nil
    visit.amb = nil
    visit.wrk_sch = nil
    visit.s_eff = nil
    visit.sk = nil
    visit.pn = nil
    visit.hp = nil
    visit.pills = nil
    visit.gave = nil
    visit.cpt = nil
    visit.cd4 = nil
    visit.estimated_date = nil
    visit.weight.should == 60.0
  end

end
