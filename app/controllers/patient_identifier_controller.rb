class PatientIdentifierController < ApplicationController

  def find
    render :layout => false
  end
  
  def get_all
    redirect_to :action => 'find' and return unless params[:identifier]
    output = ""
    @identifiers = PatientIdentifier.find_by_identifier(params[:identifier]).all_identifiers.each{|identifier|
      output += "#{identifier.identifier}<br/>"
    }
    render :text => output and return
  end
  
  def filing_number
    redirect_to :action => 'find' if params[:identifier].nil?
    render :text => PatientIdentifier.find_by_identifier(params[:identifier]).patient.filing_number
  end
  
  def national_id
    redirect_to :action => 'find' unless params[:identifier]
    render :text => PatientIdentifier.find_by_identifier(params[:identifier]).patient.national_id
  end

  def next_available_arv_id
    next_available_arv_id = PatientIdentifier.get_next_patient_identifier("Arv national id").match(/\d+/)[0] rescue nil#PatientIdentifier.next_available_arv_id.gsub(/.* /,"")
    response = <<EOF 
  arv_number_field = $('arv_number'); 
  if(arv_number_field.value == ''){
    $('tt_page_new_arv_number').getElementsByTagName("input")[0].value='#{next_available_arv_id}'
  }
EOF
    render :text => response
  end

end
