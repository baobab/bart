class FieldController < ApplicationController
  include AjaxScaffold::Controller
  
  after_filter :clear_flashes
  before_filter :update_params_filter
  
  def update_params_filter
    update_params :default_scaffold_id => "field", :default_sort => nil, :default_sort_direction => "asc"
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
    @sort_sql = Field.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Field.table_name}.#{Field.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
    if params[:name] 
      @paginator, @fields = paginate(:fields, :conditions => ["name LIKE ?", "%"+params[:name]+"%"],:order => @sort_by, :per_page => default_per_page)
#    elsif params[:form_name] 
#      @paginator, @fields = paginate(:fields, :conditions => ["form.name LIKE ?", "%"+params[:form_name]+"%"],:joins => ["RIGHT JOIN form_field ON form_field.field_id = field.field_id RIGHT JOIN form ON form_field.form_id = form.form_id "], :order => @sort_by, :per_page => default_per_page)
    else
#      @paginator, @fields = paginate(:fields, :order => @sort_by, :per_page => default_per_page)
      @paginator, @fields = paginate(:fields, :order => @sort_by, :per_page => 50)
    end
    
    render :action => "component", :layout => false
  end

  def new
    @field = Field.new
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

  def new_with_concept
    @field = Field.new
  end
  
  def create
    begin
      @field = Field.new(params[:field])
      @successful = @field.save
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    return render(:action => 'create.rjs') if request.xhr?
    if @successful
      return_to_main
    else
      @options = { :scaffold_id => params[:scaffold_id], :action => "create" }
      render :partial => 'new_edit', :layout => true
    end
  end

  def create_with_concept
    
    concept = Concept.new
    @field = Field.new
    case params["field_and_concept"]["type"]
      when "YesNoUnknown"
        @field.type = FieldType.find_by_name("select")
        concept.concept_datatype = ConceptDatatype.find_by_name("Coded")
      when "Date"
        @field.type = FieldType.find_by_name("date")
        concept.concept_datatype = ConceptDatatype.find_by_name("Date")
      when "Number"
        @field.type = FieldType.find_by_name("number")
        concept.concept_datatype = ConceptDatatype.find_by_name("Numeric")
      when "Text"
        @field.type = FieldType.find_by_name("alpha")
        concept.concept_datatype = ConceptDatatype.find_by_name("Text")
    end


    concept.name = params["field_and_concept"]["name"]
    concept.concept_class = ConceptClass.find_by_name("Question")
    concept.save
    concept.add_yes_no_unknown_concept_answers if params["field_and_concept"]["type"] == "YesNoUnknown"
    
    @field.concept = concept
    @field.name = concept.name
    @field.save
    
    flash[:notice] = "Successfully created concept and field: #{@field.name}"
    return redirect_to :action => "new_with_concept" if $!.nil?
    render :text => $! and return # only called if there is a problem
  end

  def edit
    begin
      @field = Field.find(params[:id])
      @successful = !@field.nil?
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
      @field = Field.find(params[:id])
      @successful = @field.update_attributes(params[:field])
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
      @successful = Field.find(params[:id]).destroy
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
end
