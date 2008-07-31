class LabelController < ApplicationController
  def new
    @label = {
      :name => 'National ID Label',
      :format => 1,
      :width => 776,
      :height => 329,
      :orientation => 'T',
      :fields => [
        { :name => 'Name',
          :text => '#{self.national_id}',
          :sample => 'Mercy Phiri',
          :left => 40,
          :top => 30,
          :rotation => 0,
          :font_size => 2,
          :font_horizontal_multiplier => 2,
          :font_vertical_multiplier => 2,
          :font_reverse => true },
        { :name => 'National Identifier',
          :text => '#{national_id_and_birthdate}#{sex}',
          :sample => 'P1234-5678-9012 ??/???/1974 (F)',
          :left => 40,
          :top => 80,
          :rotation => 0,
          :font_size => 2,
          :font_horizontal_multiplier => 2,
          :font_vertical_multiplier => 2,
          :font_reverse => false },
        { :name => 'Address',
          :text => '#{address}',
          :sample => 'Ngolowindo - Lilongwe',
          :left => 40,
          :top => 130,
          :rotation => 0,
          :font_size => 2,
          :font_horizontal_multiplier => 2,
          :font_vertical_multiplier => 2,
          :font_reverse => false }           
      ],
      :lines => [],            
      :frames => [
        { :left => 2,
          :top => 2,
          :width => 770,
          :height => 323,
          :frame_width => 1 }
       ],
      :barcodes => [
        { :data => 'P123456789012',
          :format => 1,
          :left => 40,
          :top => 180,
          :narrow_bar_width => 5,
          :wide_bar_width => 15,
          :height => 120,
          :rotation => 0,
          :human_readable => false } 
      ]            
    }
    render :layout => false  
  end
  
  def create
    @label = ZebraPrinter::Label.from_template(params)
    render :text => @label.print(1), :layout => false, :content_type => "text/plain"
  end
  
  def designer
    @label = ZebraPrinter::Label.from_template(params)
    render :template => "label/designer", :content_type => "image/svg+xml", :layout => false
  end

  def national_id
    patient=Patient.find(params[:id])
    send_data(patient.national_id_label, :type=> "application/label; charset=utf-8", :stream=> false, :filename=>"#{patient.id}#{rand(10000)}.lbl", :disposition => 'inline')
  end

  def test
#  id = params[:id]
    id = "foo.lbl"
    send_data("yoyoyo", :type=> "application/label; charset=utf-8", :stream=> false, :filename=>"#{id}", :disposition => 'inline')
  end

  def filing_number_only
    patient=Patient.find(params[:id])
    filing_number_label = patient.filing_number_label
    send_data(filing_number_label,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{patient.id}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def filing_number
    patient=Patient.find(params[:id])
    archived_patient = patient.patient_to_be_archived
    archive_patient_label = archived_patient.filing_number_label unless archived_patient.blank?
    filing_number_label = patient.filing_number_label
    filing_number_label+= archive_patient_label unless archive_patient_label.blank?
    send_data(filing_number_label,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{patient.id}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def filing_number_and_national_id
    patient=Patient.find(params[:id])
    archived_filing_number = patient.archived_filing_number_label
    label_commands = patient.national_id_label(2) + patient.filing_number_label
    label_commands += archived_filing_number unless archived_filing_number.blank?

    send_data(label_commands,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{patient.id}#{rand(10000)}.lbl", :disposition => "inline")
  end
  
  def transfer_out_label
    patient=Patient.find(params[:id])
    label_commands = patient.transfer_out_label(session[:encounter_datetime].to_s.to_date,params[:location])
    send_data(label_commands,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{patient.id}#{rand(10000)}.lbl", :disposition => "inline") 
  end

end
