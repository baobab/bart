class ConceptController < ApplicationController
  include AjaxScaffold::Controller

  def search_concept
   if params[:search] && params[:search].size>0
      @phrase = params[:search]
      @concepts = Concept.find_by_sql "Select * from concept where name like '%" + @phrase.to_s + "%'" 
    else
       list
    end
  end

  def search_results
    render_text "<li>" + concept.name
    if params[:search] && params[:search].size>0
      @phrase = params[:search]
      @concepts = Concept.find_by_sql "Select * from bart.concept where name like '%" + @phrase.to_s + "%'" 
      @concepts.each{|concept|
        render_text "<li>" + concept.name
      }
    else
       list
    end
  end

end
