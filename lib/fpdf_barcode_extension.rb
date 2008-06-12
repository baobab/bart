## Based on http://www.fpdf.org/en/script/script5.php
## Original Author: Olivier
## Ruby Port: Jeff Rafter
## License: Freeware

module FPDFBarcodes
  def self.included(base)
    base.class_eval do
      attr_accessor :outputs
      attr_accessor :orientations
    end
  end

  def EAN13(x, y, barcode, h = 10, w = 0.35)
    self.Barcode(x, y, barcode, h, w, 13)
  end  

  def UPC_A(x, y, barcode, h = 10, w = 0.35)
    self.Barcode(x, y, barcode, h, w, 12)
  end

  def GetCheckDigit(barcode)
    # Compute the check digit
    sum = 0
    (1..11).step(2) {|i| sum += 3*barcode[i]}
    (0..10).step(2) {|i| sum += barcode[i]}
    r = sum % 10
    r = 10 - r if r > 0
  end  

  def TestCheckDigit(barcode)
    # Test validity of check digit
    sum = 0
    (1..11).step(2) {|i| sum += 3*barcode[i]}
    (0..10).step(2) {|i| sum += barcode[i]}
    (sum + barcode[12]) % 10 == 0
  end

  def Barcode(x, y, barcode, h, w, len)
    # Padding
    barcode ||= ""
    barcode.rjust len-1, '0'
    barcode = '0' + barcode if len == 12
    
    # Add or control the check digit
    if barcode.length == 12 
      barcode += self.GetCheckDigit(barcode).to_s
    elsif !self.TestCheckDigit(barcode)
      raise 'Incorrect check digit'
    end
      
    # Convert digits to bars
    codes = {
        'A'=> {
            '0'=>'0001101','1'=>'0011001','2'=>'0010011','3'=>'0111101','4'=>'0100011',
            '5'=>'0110001','6'=>'0101111','7'=>'0111011','8'=>'0110111','9'=>'0001011'},
        'B'=> {
            '0'=>'0100111','1'=>'0110011','2'=>'0011011','3'=>'0100001','4'=>'0011101',
            '5'=>'0111001','6'=>'0000101','7'=>'0010001','8'=>'0001001','9'=>'0010111'},
        'C'=> {
            '0'=>'1110010','1'=>'1100110','2'=>'1101100','3'=>'1000010','4'=>'1011100',
            '5'=>'1001110','6'=>'1010000','7'=>'1000100','8'=>'1001000','9'=>'1110100'}
    }
    parities = {
        48 =>['A','A','A','A','A','A'],
        49 =>['A','A','B','A','B','B'],
        50 =>['A','A','B','B','A','B'],
        51 =>['A','A','B','B','B','A'],
        52 =>['A','B','A','A','B','B'],
        53 =>['A','B','B','A','A','B'],
        54 =>['A','B','B','B','A','A'],
        55 =>['A','B','A','B','A','B'],
        56 =>['A','B','A','B','B','A'],
        57 =>['A','B','B','A','B','A']
    }
    code = '101'
    p = parities[barcode[0]]
    (1..6).each {|i| code += codes[p[i-1]][barcode.at(i)] }
    code += '01010'
    (7..12).each {|i| code += codes['C'][barcode.at(i)] }
    code += '101'
    
    # Draw bars
    i = -1 
    code.each_char {|c| i += 1; self.Rect(x+i*w,y,w,h,'F') if c == '1'}

    # Print text uder barcode
    self.Text(x,y+h+11/@k,barcode.slice(-len, len))
  end
 
end


FPDF.class_eval do
  include FPDFBarcodes
end

#$pdf->EAN13(80,40,'123456789012');
