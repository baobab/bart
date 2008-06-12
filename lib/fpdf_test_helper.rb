module FPDFTestHelper
  def assert_pdf_output(pdf, page, x, y, text, font_options = {})
    outputs = pdf.outputs || {}
    output = outputs["#{page},#{x},#{y}"]
    assert_not_nil output, "No text output was found on page #{page}, at the position #{x}, #{y}"
    assert_equal x, output[:x]
    assert_equal y, output[:y]
    assert_equal text, output[:text]
    font_family, font_style = pdf.adjust_font(font_options[:font_family], font_options[:font_style])
    assert_equal font_family, output[:font_family] if font_options[:font_family]
    assert_equal font_style, output[:font_style] if font_options[:font_style]
    assert_equal font_options[:font_size], output[:font_size] if font_options[:font_size]
  end

  def assert_pdf_page_count(pdf, count)
    assert_equal pdf.page_count, count
  end
  
  def assert_pdf_page_orientation(pdf, page, orientation)
    throw "Orientation cannot be blank" if orientation.blank?
    orientation = orientation[0].chr.upcase
    assert_not_nil pdf.orientations, "No page orientations were found"
    assert_equal pdf.orientations[page]
  end

  def assert_pdf_format_and_units(pdf, format, units)
    raise NotImplementedError
  end
end

module FPDFExtensions
  def self.included(base)
    base.class_eval do
      alias_method :Cell_without_test, :Cell
      alias_method :Cell, :Cell_with_test
      
      alias_method :Text_without_test, :Text
      alias_method :Text, :Text_with_test
      
      alias_method :AddPage_without_test, :AddPage
      alias_method :AddPage, :AddPage_with_test

      attr_accessor :outputs
      attr_accessor :orientations
    end
  end

  def Cell_with_test(w,h=0,txt='',border=0,ln=0,align='',fill=0,link='')
    add_output(@x, @y, txt)
    Cell_without_test(w,h,txt,border,ln,align,fill,link)
  end

  def Text_with_test(x, y, txt)
    add_output(x, y, txt)
    Text_without_test(x, y, txt)
  end
  
  def AddPage_with_test(orientation='')
    AddPage_without_test(orientation)
    add_orientation(@CurOrientation)
  end
  
  def add_output(x, y, text)
    @outputs ||= {}
    @outputs["#{@page},#{x},#{y}"] = {:x => x, 
                                      :y => y,
                                      :text => text,
                                      :font_family => @FontFamily,
                                      :font_style => @FontStyle,
                                      :font_size => @FontSizePt}
  end
  
  def add_orientation(orientation)
    @orientations ||= []
    @orientations.push(orientation)  
  end
  
  def adjust_font(family = '', style = '')
    family.downcase!
    family = @FontFamily if family == ''
    family = 'helvetica' if family == 'arial'      
    style = '' if family == 'symbol' || family == 'zapfdingbats'
    style.upcase!
    style.gsub!('U','') unless style.index('U').nil?
    style = 'BI' if style == 'IB' 
    return family, style     
  end
  
  def page_count
     @pages ? @pages.length : 0
  end
end

FPDF.class_eval do
  include FPDFExtensions
end