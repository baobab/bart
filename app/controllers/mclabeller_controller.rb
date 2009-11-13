class MclabellerController < ApplicationController
  def menu
  end

  def print
    start_range = params[:number_start].to_i ; end_range = params[:number_end].to_i
    copies = params[:select_copies].sub('Each Patient','').to_i ; site_code = params[:select_code]
   
    label = PatientIdentifier.mclabeller_print(site_code,start_range,end_range,copies)
    send_data(label,:type=>"application/label; charset=utf-8",:stream=> false,:filename =>"#{site_code}#{rand(10000)}.lbl",:disposition => "inline")
  end

end
