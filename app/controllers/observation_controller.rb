class ObservationController < ApplicationController

  def concept
    @set = Concept.find_by_name_and_is_set(params[:name],1);
    @concepts_in_set = ConceptSet.find_all_by_concept_set(@set.concept_id, :order => "sort_weight ASC").collect{|set|set.concept}
    
#    render_text output
  end

  def edit
    @observation = Observation.find(params[:id])
  end

  def update
    @observation = Observation.find(params[:id])
    @observation.update_attributes(params[:observation])
    redirect_to :controller => "encounter", :action => 'summary'
  end
  
end
