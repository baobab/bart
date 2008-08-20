class FormController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    #@form_pages, @forms = paginate :forms, :per_page => 25
    @forms = Form.find(:all)
  end

  def show
    redirect_to(:controller => "patient", :action => "menu") and return if session[:patient_id].nil?
    
    @form = Form.find(params[:id])
    @patient = Patient.find(session[:patient_id])
    @attributes = Hash.new("")

    @ordered_fields = @form.form_fields.sort_by{|form_field| form_field.field_number}.collect{|form_field| form_field.field}

#    session[:encounter] = new_encounter_from_form(@form)

    @needs_date_picker = true if @form.fields.collect{|f|f.type.name}.include?("date")
    @adult_or_peds = (@patient.child? ? "peds" : "adult")

#    if @form.uri == "art_followup"
#      patient = Patient.find(session[:patient_id])
#    end
    
    if(File.exist?(RAILS_ROOT + "/app/views/form/#{@form.uri}.rhtml"))
      action = @form.uri
    else
      action = "show"
    end

    render :action => action, :layout => "touchscreen_form" and return
  end

  def new
    @form = Form.new
  end

  def create
    @form = Form.new(params[:form])
    if @form.save
      flash[:notice] = 'Form was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @form = Form.find(params[:id])
  end

  def order
    params[:list].each_with_index { |id,idx| FormField.update(id, :field_number => idx+1) }
    render :text => 'Updated sort order'
  end

  def add_field
    form_field = FormField.new
    form_field.form_id = params[:id]
    form_field.field_id = params[:field_id]
    form_field.field_number = FormField.find(:first, :order => "field_number DESC").field_number + 1
    form_field.save
    flash[:notice] = 'Added: ' + form_field.field.name
    redirect_to :action => 'edit', :id => params[:id]
  end
  
  def remove_field
    flash["error"] = "Could not remove" unless FormField.find(params[:form_field_id]).destroy
    redirect_to :action => 'edit', :id => params[:id]
  end

  def update
    @form = Form.find(params[:id])
    if @form.update_attributes(params[:form])
      flash[:notice] = 'Form was successfully updated.'
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

  def destroy
    Form.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
