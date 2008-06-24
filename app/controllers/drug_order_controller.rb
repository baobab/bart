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
    redirect_to :controller => "patient" and return if params["dispensed"].nil?

#		render :text => params["dispensed"].nil?.to_s and return

    Order.transaction do
      DrugOrder.transaction do #makes sure that everything saves, if not roll it all back so we don't pollute the db with half saved records
        encounter = new_encounter_by_name("Give drugs")
        order_type = OrderType.find_by_name("Give drugs")
        
        params["dispensed"].each{|drug_id, quantity_and_packs|
          quantity = quantity_and_packs["quantity"].to_i
          number_of_packs = quantity_and_packs["packs"].to_i
          tablets_per_pack = quantity/number_of_packs
          order = Order.new
          order.order_type = order_type
          order.orderer = User.current_user.id
          order.encounter = encounter
          order.save
          1.upto(number_of_packs){ |pack_index|
            drug_order = DrugOrder.new
            drug_order.order = order
            drug_order.drug_inventory_id = drug_id
            drug_order.quantity = tablets_per_pack
            drug_order.save
          }
        }
        encounter.save
      end
    end

    print_and_redirect("/label_printing/print_drug_dispensed", "/patient/menu", "Printing visit summary")

  end
  
  def prescribed_dosages
#   Ugly hack - pluses don't seem to make it as params, so we put it back in here
    params[:regimen].sub!(/   /," + ")
   
    patient = Patient.find(session[:patient_id])
    recommended_prescription =  DrugOrder.recommended_art_prescription(patient.current_weight)[params[:regimen]]

    prescription = Array.new
    recommended_prescription.each{|pres|
      prescription << Prescription.new(pres.drug.name, pres.frequency, pres.units) if pres.drug
    }
   
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

