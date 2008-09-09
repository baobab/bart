class DrugBarcodeController < ApplicationController
  def index
    redirect_to :action => "scan"
  end

  def scan
    if params["barcode"]
      @scanned_barcode = DrugBarcode.find_by_barcode(params["barcode"])
      redirect_to :action => "new", :barcode => params["barcode"] and return if @scanned_barcode.nil?
    end

    @all_barcodes = DrugBarcode.find(:all)
# drugs requiring barcodes
    @drugs_needing_barcodes = Drug.find(:all).collect{|drug| drug if drug.barcodes.empty? }.compact
    render :layout => false
  end

  def new
    @barcode_string = params["barcode"]
    redirect_to :action => "scan" if @barcode_string.nil?
  end

  def save
    drug_barcode = DrugBarcode.new(params[:barcode])
    drug_barcode.save
    redirect_to :action => "scan", :barcode => drug_barcode.barcode
  end

	def to_drug_id
		barcode = params[:id]
		drug_barcode = DrugBarcode.find_by_barcode(barcode)
		render:text => drug_barcode.drug_id and return unless drug_barcode.nil?
		render:text => ""
	end
end
