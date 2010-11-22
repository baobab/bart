class DrugController < ApplicationController
  include AjaxScaffold::Controller
  
  after_filter :clear_flashes
  before_filter :update_params_filter
  
  def update_params_filter
    update_params :default_scaffold_id => "drug", :default_sort => nil, :default_sort_direction => "asc"
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
    @sort_sql = Drug.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Drug.table_name}.#{Drug.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
    if params[:name] 
      @paginator, @drugs = paginate(:drugs, :conditions => ["name LIKE ?", "%"+params[:name]+"%"],:order => @sort_by, :per_page => default_per_page)
    else
      @paginator, @drugs = paginate(:drugs, :order => @sort_by, :per_page => default_per_page)
    end
     
    render :action => "component", :layout => false
  end

  def new
    @drug = Drug.new
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
      @drug = Drug.new(params[:drug])
      @successful = @drug.save
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

  def edit
    begin
      @drug = Drug.find(params[:id])
      @successful = !@drug.nil?
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
      @drug = Drug.find(params[:id])
      @successful = @drug.update_attributes(params[:drug])
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
      @successful = Drug.find(params[:id]).destroy
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

  def delivery
    @drug_id = params[:void] || params[:edit]
    @encounter_id = params[:encounter_id]
    @delivery_type = "create_delivery"
    @delivery_type = "void" unless params[:void].blank?
    @delivery_type = "edit_stock" unless params[:edit].blank?
    @pharmacy_encunter_type = PharmacyEncounterType.find_by_name("New deliveries").id if @delivery_type == "create_delivery"

    unless @encounter_id.blank? and @delivery_type == "create_delivery"
    raise "xxxxxxxxxxxxxx"
      pharmacy_encunter = Pharmacy.active.find(@encounter_id)
      delivery_date = pharmacy_encunter.encounter_date
      @drug_name = Drug.find(pharmacy_encunter.drug_id).name rescue nil
      @delivery_year = delivery_date.year
      @delivery_month = delivery_date.month
      @delivery_day = delivery_date.day
    end
    render :layout => false
  end

  


  def create_delivery
    encounter_type = params[:pharmacy_encunter_type].to_i
    drug_id = Drug.find_by_name(params[:drug_name]).id
    delivery_year = params[:delivery_year]
    delivery_month = params[:delivery_month]
    delivery_day = params[:delivery_day]
    expiry_year = params[:expiry_year]
    expiry_month = params[:expiry_month]
    expiry_day = params[:expiry_day] 

    number_of_pills_in_a_tin = params[:number_of_pills_in_a_tin]
    number_of_tins = params[:number_of_tins]
    delivery_date =  ("#{delivery_year}-#{delivery_month}-#{delivery_day}").to_date rescue nil
    expiry_date =  ("#{expiry_year}-#{expiry_month}-#{expiry_day}").to_date rescue nil
    number_of_pills = ((params[:number_of_tins].to_i)*(params[:number_of_pills_in_a_tin].to_i))
    return if delivery_date.blank?

    Pharmacy.new_delivery(drug_id,number_of_pills,delivery_date,encounter_type,expiry_date)
    redirect_to :action => "manage" ; return
  end

  def stock_list
    drug_id = Drug.find_by_name(params[:drug_name]).id
    @drug_name = params[:drug_name]
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    @stock = Pharmacy.active.find(:all,
      :conditions =>["drug_id=? AND pharmacy_encounter_type=?",drug_id,encounter_type])
  end

  def edit_stock
    if request.method == :post
      drug_id = Drug.find_by_name(params[:drug_name]).id
      pills = (params[:number_of_pills_in_a_tin].to_i * params[:number_of_tins].to_i)
      Pharmacy.drug_dispensed_stock_adjustment(drug_id,pills,Date.today,params[:edit_reason])
      redirect_to :action => "manage" and return
    end  
    render :layout => false
  end

  def void
    pharmacy_encunter = Pharmacy.active.find(params[:encounter_id])
    pharmacy_encunter.voided = 1
    pharmacy_encunter.voided_by = User.current_user.id
    pharmacy_encunter.date_voided = Time.now()
    pharmacy_encunter.void_reason = params[:void_reason]
    pharmacy_encunter.save
    redirect_to :action => "manage" ; return
  end

  def report
    #drug_stock_report
    @quater = params[:quater]
    if @quater == "set date"
      start_date = params[:start_date].to_date ; end_date = params[:end_date].to_date
      @quater = "Set Time: #{start_date} - #{end_date}"
    else  
      date = Report.cohort_date_range(@quater)
      start_date = date.first ; end_date = date.last
    end

#TODO
#need to redo the SQL query
    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id
    new_deliveries = Pharmacy.active.find(:all,
      :conditions =>["pharmacy_encounter_type=?",encounter_type],
      :order => "encounter_date DESC,date_created DESC")
    
    current_stock = {}
    new_deliveries.each{|delivery|
      current_stock[delivery.drug_id] = delivery if current_stock[delivery.drug_id].blank?
    }

    @stock = {}
    current_stock.each{|delivery_id , delivery|
      first_date = Pharmacy.active.find(:first,:conditions =>["drug_id =?",
                   delivery.drug_id],:order => "encounter_date").encounter_date.to_date rescue nil
      next if first_date.blank?
      next if first_date > start_date
                   
      drug = Drug.find(delivery.drug_id)
      drug_name = drug.name
      @stock[drug_name] = {"current_stock" => 0,"dispensed" => 0,"prescribed" => 0, "consumption_per" => ""}
      @stock[drug_name]["current_stock"] = Pharmacy.current_stock_as_from(drug.id,start_date,end_date)
      @stock[drug_name]["dispensed"] = Pharmacy.dispensed_drugs_since(drug.id,start_date,end_date)
      @stock[drug_name]["prescribed"] = Pharmacy.prescribed_drugs_since(drug.id,start_date,end_date)
      @stock[drug_name]["consumption_per"] = ((@stock[drug_name]["dispensed"].to_f / @stock[drug_name]["current_stock"].to_f) * 100.to_f).round.to_s + " %" rescue "0 %"
    }
  end

  def expiry_date
    unless params[:stock_id].blank?
      stock = Pharmacy.find_by_pharmacy_module_id(params[:stock_id])
      stock.value_coded = Concept.find_by_name("Out of stock").id
      stock.save
    end
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    @expiry_dates = Pharmacy.active.find(:all,
      :conditions =>["value_coded IS NULL AND pharmacy_encounter_type =? AND expiry_date IS NOT NULL",encounter_type])
    render :layout => false
  end

  def remove_stock
    Pharmacy.remove_stock(params[:encounter_id])
    redirect_to :action => "stock_list",:drug_name => Drug.find(params[:drug_id]).name
  end

end
