require File.dirname(__FILE__) + '/../spec_helper'

describe DrugBarcode do
  fixtures :drug_barcodes

  sample({
    :quantity => 60,
    :drug_id => 56,
    :barcode => "D100000000056",
  })

  it "should be valid" do
    drug_barcode = create_sample(DrugBarcode)
    drug_barcode.should be_valid
  end
  
end
