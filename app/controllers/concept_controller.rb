class ConceptController < ApplicationController
  include AjaxScaffold::Controller
  
  after_filter :clear_flashes
  before_filter :update_params_filter
  
  def update_params_filter
    update_params :default_scaffold_id => "concept", :default_sort => nil, :default_sort_direction => "asc"
  end
  def index
    redirect_to :action => 'list'
  end
  def return_to_main
    # If you have multiple scaffolds on the same view then you will want to change this to
    # to whatever controller/action shows all the views 
    # (ex: redirect_to :controller => 'AdminConsole', :action => 'index')
    redirect_to :action => 'list'
  end

  def list
  end

  def list_set
    @set = Concept.find_by_name_and_is_set(params[:name],1);
    @concepts_in_set = ConceptSet.find_all_by_concept_set(@set.concept_id, :order => "sort_weight ASC").collect{|set|set.concept}
    
#    render_text output
  end
  
  # All posts to change scaffold level variables like sort values or page changes go through this action
  def component_update
    @show_wrapper = false # don't show the outer wrapper elements if we are just updating an existing scaffold 
    if request.xhr?
      # If this is an AJAX request then we just want to delegate to the component to rerender itself
      component
    else
      # If this is from a client without javascript we want to update the session parameters and then delegate
      # back to whatever page is displaying the scaffold, which will then rerender all scaffolds with these update parameters
      return_to_main
    end
  end

  def component  
    @show_wrapper = true if @show_wrapper.nil?
    @sort_sql = Concept.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Concept.table_name}.#{Concept.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
    if params[:name] 
      @paginator, @concepts = paginate(:concepts, :conditions => ["name LIKE ?", "%"+params[:name]+"%"],:order => @sort_by, :per_page => default_per_page)
    else
      @paginator, @concepts = paginate(:concepts, :order => @sort_by, :per_page => default_per_page)
    end
    
    render :action => "component", :layout => false
  end

  def new
    @concept = Concept.new
    @successful = true

    return render(:action => 'new.rjs') if request.xhr?

    # Javascript disabled fallback
    if @successful
      @options = { :action => "create" }
      render :partial => "new_edit", :layout => true
    else 
      return_to_main
    end
  end
  
  def create

    begin
      @concept = Concept.new(params[:concept])
      @concept.create_field if params[:create_field]
      @concept.add_yes_no_concept_answers if params[:add_yes_no]
      @concept.add_yes_no_unknown_concept_answers if params[:add_yes_no_unknown]
      @concept.add_yes_no_unknown_not_applicable_concept_answers if params[:add_yes_no_unknown_not_applicable]
      @successful = @concept.save
      flash[:error] = 'Concept was successfully created.'
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    return render(:action => 'create.rjs') if request.xhr?
    if @successful || @autosave
      return_to_main
    else
      @options = { :scaffold_id => params[:scaffold_id], :action => "create" }
      render :partial => 'new_edit', :layout => true
    end
  end

  def edit
    begin
      @concept = Concept.find(params[:id])
      @successful = !@concept.nil?
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    return render(:action => 'edit.rjs') if request.xhr?

    if @successful
      @options = { :scaffold_id => params[:scaffold_id], :action => "update", :id => params[:id] }
      render :partial => 'new_edit', :layout => true
    else
      return_to_main
    end    
  end

  def update
    begin
      @concept = Concept.find(params[:id])
      @successful = @concept.update_attributes(params[:concept])
      @concept.create_field if params[:create_field]
      @concept.add_yes_no_concept_answers if params[:add_yes_no]
      @concept.add_yes_no_unknown_concept_answers if params[:add_yes_no_unknown]
      @concept.add_yes_no_unknown_not_applicable_concept_answers if params[:add_yes_no_unknown_not_applicable]
      flash[:notice] = 'Concept was successfully updated.'
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    return render(:action => 'update.rjs') if request.xhr?

    if @successful
      return_to_main
    else
      @options = { :action => "update" }
      render :partial => 'new_edit', :layout => true
    end
  end

  def destroy
    begin
      @successful = Concept.find(params[:id]).destroy
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    return render(:action => 'destroy.rjs') if request.xhr?
    
    # Javascript disabled fallback
    return_to_main
  end
  
  def cancel
    @successful = true
    
    return render(:action => 'cancel.rjs') if request.xhr?
    
    return_to_main
  end
  
  def search_concept
   if params[:search] && params[:search].size>0
      @phrase = params[:search]
      @concepts = Concept.find_by_sql "Select * from concept where name like '%" + @phrase.to_s + "%'" 
    else
       list
    end
# params[:action] lets search and sort get _search and _sort
# render :partial=>params[:action], :layout=>false
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
