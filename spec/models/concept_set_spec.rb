require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptSet do
  # You can move this to spec_helper.rb
  set_fixture_class :concept_set => ConceptSet
  fixtures :concept_set, :concept

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
    ConceptSet.find_by_concept_id(316).to_s.should == "WHO Stage 2 peds: Unexplained persistent hepatomegaly and splenomegalyPapular itchy skin eruptionsExtensive wart virus infectionExtensive molluscum contagiosumRecurrent oral ulcerationsUnexplained persistent parotid gland enlargementLineal gingival erythemaHerpes zosterRecurrent or chronic respiratory tract infections (sinusitis, otorrhoea, tonsillitis, otitis media)Fungal nail infections"
  end
  
  it "raise before save"
  
  it "should display concept set  name" do
    ConceptSet.find_by_concept_id(316).name.should == "WHO Stage 2 peds"
  end
 
  it "should find concept set by name" do
    ConceptSet.find_by_name("WHO Stage 2 peds").last.should == ConceptSet.find_by_concept_id(316)
  end 
 
 
  it "should create concept sets" 
  
end
