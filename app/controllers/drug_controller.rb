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
    if params[:report_type] == 'verify_stock_count'
      @delivery_type = 'verify_stock_count'
      return
    end
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

  def verify_stock_count

    drug_id = Drug.find_by_name(params[:drug_name]).id
    delivery_year = params[:delivery_year]
    delivery_month = params[:delivery_month]
    delivery_day = params[:delivery_day]

    number_of_pills_in_a_tin = params[:number_of_pills_in_a_tin]
    number_of_tins = params[:number_of_tins]
    date =  ("#{delivery_year}-#{delivery_month}-#{delivery_day}").to_date rescue nil
    number_of_pills = ((params[:number_of_tins].to_i)*(params[:number_of_pills_in_a_tin].to_i))

    encounter_type = PharmacyEncounterType.find_by_name("Tins currently in stock").id 
    delivery =  Pharmacy.new()                                                    
    delivery.pharmacy_encounter_type = encounter_type                         
    delivery.drug_id = drug_id                                                
    delivery.encounter_date = date                                 
    delivery.value_numeric = number_of_pills
    delivery.save                                                             

    flash[:notice] = "#{params[:drug_name]} count successfully verified"
    redirect_to :action => "manage" ; return
    
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
    delivery_barcode = params[:delivery_barcode]

    number_of_pills_in_a_tin = params[:number_of_pills_in_a_tin]
    number_of_tins = params[:number_of_tins]
    delivery_date =  ("#{delivery_year}-#{delivery_month}-#{delivery_day}").to_date rescue nil
    expiry_date =  ("#{expiry_year}-#{expiry_month}-#{expiry_day}").to_date rescue nil
    number_of_pills = ((params[:number_of_tins].to_i)*(params[:number_of_pills_in_a_tin].to_i))
    return if delivery_date.blank?

    Pharmacy.new_delivery(drug_id,number_of_pills,delivery_date,encounter_type,expiry_date,delivery_barcode)
    #add a notice
    flash[:notice] = "#{params[:drug_name]} successfully entered"
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
      drug = Drug.find_by_name(params[:drug_name])
      pills = (params[:number_of_pills_in_a_tin].to_i * params[:number_of_tins].to_i)

      encounter_year = params[:expiry_year]                                      
      encounter_month = params[:expiry_month]                                    
      encounter_day = params[:expiry_day]                                       
      encounter_date = ("#{encounter_year}-#{encounter_month}-#{encounter_day}").to_date 

      if params[:edit_reason] == 'receipt'
        delivery_year = params[:delivery_year]                                      
        delivery_month = params[:delivery_month]                                    
        delivery_day = 1                                       
        expiry_date = ("#{delivery_year}-#{delivery_month}-#{delivery_day}").to_date 
        Pharmacy.new_delivery(drug.id,pills,encounter_date,nil,expiry_date,'Receipt')
      else
        Pharmacy.alter(drug,pills,encounter_date,params[:edit_reason])
      end
      flash[:notice] = "#{params[:drug_name]} successfully changed"
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
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
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
      @stock[drug_name] = {"confirmed_closing" => 0,"dispensed" => 0,"current_stock" => 0 ,
        "confirmed_opening" => 0, "start_date" => start_date , "end_date" => end_date,
        "relocated" => 0, "receipts" => 0,"expected" => 0}
      @stock[drug_name]["dispensed"] = Pharmacy.dispensed_drugs_since(drug.id,start_date,end_date)
      @stock[drug_name]["confirmed_opening"] = Pharmacy.verify_stock_count(drug.id,start_date,start_date)
      @stock[drug_name]["confirmed_closing"] = Pharmacy.verify_stock_count(drug.id,start_date,end_date)
      @stock[drug_name]["current_stock"] = Pharmacy.current_stock_as_from(drug.id,start_date,end_date)
      @stock[drug_name]["relocated"] = Pharmacy.relocated(drug.id,start_date,end_date)
      @stock[drug_name]["receipts"] = Pharmacy.receipts(drug.id,start_date,end_date)
      @stock[drug_name]["expected"] = Pharmacy.expected(drug.id,start_date,end_date)
    }
  end

  def expiry_date
    unless params[:stock_id].blank?
      stock = Pharmacy.find_by_pharmacy_module_id(params[:stock_id])
      stock.value_coded = Concept.find_by_name("Out of stock").id
      stock.voided = 1
      stock.save
      Pharmacy.drug_dispensed_stock_adjustment(stock.drug_id, stock.value_numeric, Date.today, "Out of stock")
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

  def dispensed_pills 
    location_id = Location.current_location.id
    @start_date =  "#{params[:start_year]}-#{params[:start_month]}-#{params[:start_day]}".to_date
    @end_date =  "#{params[:end_year]}-#{params[:end_month]}-#{params[:end_day]}".to_date
    encounter_type = EncounterType.find_by_name("Give drugs")
    
    dispensed = Encounter.find(:all,:order => "encounter_datetime ASC",
      :select => "encounter_datetime, drug.name drug_name , quantity",
      :joins => "INNER JOIN orders o ON o.encounter_id = encounter.encounter_id
      AND encounter.location_id = #{location_id} AND encounter_type = #{encounter_type.id}
      AND voided = 0 INNER JOIN drug_order d ON d.order_id = o.order_id
      INNER JOIN drug ON d.drug_inventory_id = drug.drug_id",
      :conditions =>["encounter_datetime >= ? AND encounter_datetime <= ?",
      @start_date.strftime("%Y-%m-%d 00:00:00"),@end_date.strftime("%Y-%m-%d 23:59:59")])
  
    @pills_dispensed = Hash.new(0)
    
    (dispensed || []).each do |record|
      @pills_dispensed["#{record.encounter_datetime.to_date}::#{record.drug_name}"] += record.quantity.to_f
    end 

=begin 
    encounter_type = EncounterType.find_by_name("ART visit")
    concept = Concept.find_by_name("Number of condoms given")

    dispensed = Encounter.find(:all,:order => "encounter_datetime ASC",
      :select => "encounter_datetime , value_numeric",
      :joins => "INNER JOIN obs ON obs.encounter_id = encounter.encounter_id
      AND encounter.location_id = #{location_id} AND voided = 0
      AND encounter_type = #{encounter_type.id} AND concept_id = #{concept.id}",
      :conditions =>["encounter_datetime >= ? AND encounter_datetime <= ?",
      @start_date.strftime("%Y-%m-%d 00:00:00"),@end_date.strftime("%Y-%m-%d 23:59:59")])

    (dispensed || []).each do |record|
      @pills_dispensed["#{record.encounter_datetime.to_date}::Condoms"] += record.value_numeric.to_i
    end 
=end
  end

  def patient_list
    location_id = Location.current_location.id
    @date =  params[:date].to_date
    @drug = Drug.find_by_name(params[:name])

    encounter_type = EncounterType.find_by_name("Give drugs")
    identifier_type = PatientIdentifierType.find_by_name("Arv national id")
    
    dispensed = Encounter.find(:all,:order => "encounter_datetime ASC",
      :select => "encounter.patient_id,identifier,given_name,family_name,SUM(quantity) quantity",
      :joins => "INNER JOIN orders o ON o.encounter_id = encounter.encounter_id
      AND encounter.location_id = #{location_id} AND encounter_type = #{encounter_type.id}
      AND voided = 0 INNER JOIN drug_order d ON d.order_id = o.order_id
      INNER JOIN drug ON d.drug_inventory_id = drug.drug_id AND drug.drug_id = #{@drug.id}
      LEFT JOIN patient_identifier i ON i.patient_id = encounter.patient_id 
      AND identifier_type = #{identifier_type.id} AND i.voided = 0 
      INNER JOIN patient_name n ON n.patient_id = encounter.patient_id 
      AND n.voided = 0 AND n.patient_name_id =
      (SELECT patient_name_id FROM patient_name x WHERE voided = 0 
      AND patient_id=encounter.patient_id ORDER BY patient_name_id DESC LIMIT 1)",
      :conditions =>["encounter_datetime >= ? AND encounter_datetime <= ?",
      @date.strftime("%Y-%m-%d 00:00:00"),@date.strftime("%Y-%m-%d 23:59:59")],
      :group => "encounter.patient_id", :order => "n.family_name ASC")
  
    @list = Hash.new()
    
    (dispensed || []).each do |record|
      @list[record.patient_id] = {:given_name => record.given_name,
        :family_name => record.family_name,:identifier => record.identifier,
        :quantity => record.quantity.to_f } 
    end 
  end

end
