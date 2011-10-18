class DrugOrderController < ApplicationController

	def dispense
		@barcode_drugs = Hash.new
		DrugBarcode.find(:all).each { |db|
			@barcode_drugs[db.barcode] = [db.drug_id, db.quantity, db.drug.name] if db and db.drug
		}
		
		# when no drugs have been prescribed
		#@drugs = [] 
    #
    @patient = Patient.find(session[:patient_id])
    current_followup_encounter = @patient.encounters.find_by_type_name_and_date("ART Visit", session[:encounter_datetime]).last

    if current_followup_encounter.blank? 
      current_pre_art_followup_encounter = (@patient.encounters.find_by_type_name_and_date("Pre ART visit", session[:encounter_datetime]).last) rescue nil
      current_followup_encounter = current_pre_art_followup_encounter unless current_pre_art_followup_encounter.blank?
    end

#    render :text => current_followup_encounter.to_s and return
#    render :text => current_followup_encounter.to_dispensations and return
 
		# initialize these with default values
		@quantity_dispensed = Hash.new(0)
		@packs_dispensed = Hash.new(0)
		@patient.drug_orders_for_date(session[:encounter_datetime]).each{|drug_order|
			@quantity_dispensed[drug_order.drug.id] += drug_order.quantity
			@packs_dispensed[drug_order.drug.id] += 1
		}
#    render :text => current_followup_encounter.to_dispensations and return
		begin
			raise "No followup visit for #{session[:encounter_datetime]}" if current_followup_encounter.nil?
			@prescriptions_for_patient = current_followup_encounter.to_dispensations
		rescue
			@prescriptions_for_patient = nil
		end

    @drugs_to_display = Array.new
    @drugs_to_display += @quantity_dispensed.keys if @quantity_dispensed
    @drugs_to_display += @prescriptions_for_patient.keys if @prescriptions_for_patient
    @drugs_to_display = @drugs_to_display.uniq

		render(:layout => 'dispense')

	end

  def recommended_prescription
#   Ugly hack - pluses don't seem to make it as params, so we put it back in here
    params[:regimen].sub!(/   /," + ")
    patient = Patient.find(session[:patient_id])
    @recommended_prescription = DrugOrder.recommended_art_prescription(patient.current_weight)[params[:regimen]]

    render :layout => false;
  end

  def create
    if params["dispensed"].blank?
      unless session[:patient_program].blank?
        redirect_to :controller => "patient",:action => "retrospective_data_entry",
          :id => params[:id],:visit_added => true and return 
      else
        redirect_to :controller => "patient" and return 
      end  
    end  

    patient = Patient.find(session[:patient_id])
    encounter = nil
    Order.transaction do
      DrugOrder.transaction do #makes sure that everything saves, if not roll it all back so we don't pollute the db   with half saved records
        encounter = new_encounter_by_name("Give drugs")
        order_type = OrderType.find_by_name("Give drugs")
        params["dispensed"].each{|drug_id, quantity_and_packs|
          number_of_orders = []
          quantity_and_packs.each do |quantity_and_pack|
            number_of_orders << [quantity_and_pack[0],quantity_and_pack[1]]
          end
          order = Order.new
          order.order_type = order_type
          order.orderer = User.current_user.id
          order.encounter = encounter
          order.save
          number_of_orders.each do |quantity_and_pack|
            number_of_packs = quantity_and_pack[1].to_i
            quantity = quantity_and_pack[0].to_i
            tablets_per_pack = quantity
            1.upto(number_of_packs){ |pack_index|
              drug_order = DrugOrder.new
              drug_order.order = order
              drug_order.drug_inventory_id = drug_id
              drug_order.quantity = tablets_per_pack
              drug_order.save
            }
          end
        }
        encounter.save
      end
    end
 
    if session[:patient_program] == "HIV"
      patient.next_appointment_date(params[:encounter_date].to_date,encounter.id,true) unless encounter.blank?
      patient.reset_outcomes
      patient.reset_adherence_rates
    else  
      patient.next_appointment_date(session[:encounter_datetime].to_date,encounter.id,true) unless encounter.blank?
    end  
    #DrugOrder.dispensed_drugs(patient,params[:dispensed],session[:encounter_datetime]) 
    if params[:adding_visit] == "true"
      session[:encounter_datetime] = nil
      redirect_to :controller => "patient" ,:action => "retrospective_data_entry",
                  :visit_added => "true",:id => patient.id ; return 
    else  
      redirect_to("/patient/next_appointment_date")
      #print_and_redirect("/label_printing/print_drug_dispensed", "/patient/menu", "Printing visit summary")
    end
  end
  
  def prescribed_dosages
#   Ugly hack - pluses don't seem to make it as params, so we put it back in here
    params[:regimen].sub!(/   /," + ")
   
    patient = Patient.find(session[:patient_id])
    current_date = session[:encounter_datetime].to_date rescue nil
    if params[:use_regimen_short_names] 
      regimen_name = Concept.find(params[:regimen]).name
      recommended_prescription =  DrugOrder.recommended_art_prescription(patient.current_weight(current_date))[regimen_name]
    else  
      recommended_prescription =  DrugOrder.recommended_art_prescription(patient.current_weight(current_date))[params[:regimen]]
    end

    prescription = Array.new
    recommended_prescription.each{|pres|
      prescription << Prescription.new(pres.drug.name, pres.frequency, pres.units) if pres.drug
    } if recommended_prescription
   
    prescription_by_time = Hash.new 
    prescription_by_time["Morning"] = prescription.collect{|pres|pres if pres.frequency == "Morning"}.compact
    prescription_by_time["Evening"] = prescription.collect{|pres|pres if pres.frequency == "Evening"}.compact
    
    render :text => <<EOF
      prescription = #{prescription.to_json};
      prescriptionByTime = #{prescription_by_time.to_json};
EOF
    return
  end

end

