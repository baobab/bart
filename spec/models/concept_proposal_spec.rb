require File.dirname(__FILE__) + '/../spec_helper'

describe ConceptProposal do

  sample({
    :concept_proposal_id => 1,
    :concept_id => 1,
    :encounter_id => 1,
    :original_text => '',
    :final_text => '',
    :obs_id => 1,
    :obs_concept_id => 1,
    :state => '',
    :comments => '',
    :creator => 1,
    :date_created => Time.now,
    :changed_by => 1,
    :date_changed => Time.now,
  })

  it "should be valid" do
    concept_proposal = create_sample(ConceptProposal)
    concept_proposal.should be_valid
  end
  
end
