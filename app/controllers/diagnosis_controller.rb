class DiagnosisController < ApplicationController

  def list
    concepts = Concept.find(:all,
                 :joins => "INNER JOIN concept_set s ON concept.concept_id=s.concept_id",
                 :conditions => ["s.concept_set=? AND concept.name LIKE '%#{params[:value]}%'",27])
    render :text => @options = concepts.collect{|concept|"<li>#{concept.name}</li>"}
    return
  end
  
  def new
    concepts = Concept.find(:all,
                 :joins => "INNER JOIN concept_set s ON concept.concept_id=s.concept_id",
                 :conditions => ["s.concept_set=? AND concept.name LIKE '%#{params[:value]}%'",27])
    @options = concepts.collect{|concept|concept.name}
  end
end
