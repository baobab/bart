require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptSet do

  sample({
    :concept_id => 1,
    :concept_set => 1,
    :creator => 1,
    :date_created => Time.now
  })

  it "should be valid" do
    #concept_set = create_sample(ConceptSet)
    concept_set = ConceptSet.new(:concept_set => 1, :sort_weight => nil, :creator => 1)
    concept_set.should be_valid
  end
  
  it "should display concept as string" do
    ConceptSet.find_by_concept_id(316).to_s.should == "WHO Stage 2 peds: Unexplained persistent hepatomegaly and splenomegaly, Papular itchy skin eruptions, Extensive wart virus infection, Extensive molluscum contagiosum, Recurrent oral ulcerations, Unexplained persistent parotid gland enlargement, Lineal gingival erythema, Herpes zoster, Recurrent or chronic respiratory tract infections (sinusitis, otorrhoea, tonsillitis, otitis media), Fungal nail infections"
  end
  
  it "should display concept set name" do
    ConceptSet.find_by_concept_id(316).name.should == "WHO Stage 2 peds"
  end
 
  it "should find concept set by name" do
    ConceptSet.find_by_name("WHO Stage 2 peds").last.should == ConceptSet.find_by_concept_id(316)
  end 
 
end
