require 'rubygems'
require 'test/unit'
require 'fileutils'
require File.expand_path(File.dirname(__FILE__) + "/../lib/zebra_printer")
require File.expand_path(File.dirname(__FILE__) + "/../lib/visit_label")

class ZebraPrinterTest < Test::Unit::TestCase

  def setup
    @label = ZebraPrinter::Label.new
  end

  def test_should_use_label_defaults
    assert_equal "\nN\nq776\nQ329\nZT\n", @label.output
  end

  def test_should_use_standard_label_defaults
    @label = ZebraPrinter::StandardLabel.new
    assert_equal "\nN\nq776\nQ329\nZT\n", @label.output
  end
  
  def test_should_print_copies
    assert_equal "\nN\nq776\nQ329\nZT\nP2\n", @label.print(2)
  end
  
  def test_should_issue_reset_printer_command
    assert_equal "\nN\nq776\nQ329\nZT\n^@\n", @label.reset_printer
  end
  
  def test_should_draw_text
    @label.draw_text("Yo!",1,2,0,1,1,1,true)
    assert_equal "\nN\nq776\nQ329\nZT\nA1,2,0,1,1,1,R,\"Yo!\"\n", @label.output     
  end
  
  def test_should_draw_line
    @label.draw_line(1,2,3,4,0)
    @label.draw_line(1,2,3,4,1)
    @label.draw_line(1,2,3,4,2)
    assert_equal "\nN\nq776\nQ329\nZT\nLO1,2,3,4\nLW1,2,3,4\nLE1,2,3,4\n", @label.output     
  end
  
  def test_should_draw_frame
    @label.draw_frame(1,2,3,4,5)
    assert_equal "\nN\nq776\nQ329\nZT\nX1,2,5,3,4\n", @label.output     
  end
  
  def test_should_draw_barcode
    @label.draw_barcode(1,2,0,1,5,15,120,false,"Yo!")
    assert_equal "\nN\nq776\nQ329\nZT\nB1,2,0,1,5,15,120,N,\"Yo!\"\n", @label.output     
  end
  
  def test_should_draw_barcode_and_print_data
    @label.draw_barcode(1,2,0,1,5,15,120,true,"Yo!")
    assert_equal "\nN\nq776\nQ329\nZT\nB1,2,0,1,5,15,120,B,\"Yo!\"\n", @label.output     
  end
  
  def test_should_draw_text_from_template
    @label = ZebraPrinter::Label.from_template({
      :name => 'National ID Label',
      :format => 1,
      :orientation => 'T',
      :fields => [
        { :name => 'Name',
          :text => 'Yo!',
          :left => 1,
          :top => 2,
          :rotation => 0,
          :font_size => 1,
          :font_horizontal_multiplier => 1,
          :font_vertical_multiplier => 1,
          :font_reverse => true } 
      ],
      :lines => [],            
      :frames => [],
      :barcodes => []}, nil)
    assert_equal "\nN\nq776\nQ329\nZT\nA1,2,0,1,1,1,R,\"Yo!\"\n", @label.output     
  end
  
  def test_should_draw_line_from_template
    @label = ZebraPrinter::Label.from_template({
      :name => 'National ID Label',
      :format => 1,
      :orientation => 'T',
      :fields => [],
      :lines => [
        { :left => 1,
          :top => 2,
          :width => 3,
          :height => 4,
          :color => 0 },
        { :left => 1,
          :top => 2,
          :width => 3,
          :height => 4,
          :color => 1 },
        { :left => 1,
          :top => 2,
          :width => 3,
          :height => 4,
          :color => 2 }],
      :frames => [],
      :barcodes => []}, nil)
    assert_equal "\nN\nq776\nQ329\nZT\nLO1,2,3,4\nLW1,2,3,4\nLE1,2,3,4\n", @label.output     
  end
  
  def test_should_draw_frame_from_template
    @label = ZebraPrinter::Label.from_template({
      :name => 'National ID Label',
      :format => 1,
      :orientation => 'T',
      :fields => [],
      :lines => [],
      :frames => [     
        { :left => 1,
          :top => 2,
          :width => 3,
          :height => 4,
          :frame_width => 5 }],
      :barcodes => []}, nil)
    assert_equal "\nN\nq776\nQ329\nZT\nX1,2,5,3,4\n", @label.output     
  end
  
  def test_should_draw_barcode_from_template
    @label = ZebraPrinter::Label.from_template({
      :name => 'National ID Label',
      :format => 1,
      :orientation => 'T',
      :fields => [],
      :lines => [],
      :frames => [],     
      :barcodes => [
        { :data => 'Yo!',
          :format => 1,
          :left => 1,
          :top => 2,
          :narrow_bar_width => 1,
          :wide_bar_width => 5,
          :height => 120,
          :rotation => 0,
          :human_readable => false }]}, nil)
    assert_equal "\nN\nq776\nQ329\nZT\nB1,2,0,1,1,5,120,N,\"Yo!\"\n", @label.output     
  end

  def test_should_not_print_blank_word_multi_text
    @label.draw_multi_text("")
    assert_equal "\nN\nq776\nQ329\nZT\n", @label.output     
  end
  
  def test_should_print_one_word_multi_text
    @label.draw_multi_text("Yo")
    assert_equal "\nN\nq776\nQ329\nZT\nA13,0,0,1,1,1,N,\"Yo\"\n", @label.output     
  end
  
  def test_should_print_multi_word_multi_text
    @label.draw_multi_text("Yo yo")
    assert_equal "\nN\nq776\nQ329\nZT\nA13,0,0,1,1,1,N,\"Yo yo\"\n", @label.output     
  end
  
  def test_should_print_very_long_word_clipped
    @label.draw_multi_text("ThisIsAnExtremelyLongWordThatWontFitOntoASingleLineOfTextButShouldPrintAnywayOkayThanksBye")
    assert_equal "\nN\nq776\nQ329\nZT\nA13,0,0,1,1,1,N,\"ThisIsAnExtremelyLongWordThatWontFitOntoASingleLineOfTextButShouldPrintAnywayOkayThanksBye\"\n", @label.output     
  end
  
  def test_should_print_very_long_word_between_other_words_clipped
    @label.draw_multi_text("Yo ThisIsAnExtremelyLongWordThatWontFitOntoASingleLineOfTextButShouldPrintAnywayOkayThanksBye yo")
    assert_equal "\nN\nq776\nQ329\nZT\nA13,0,0,1,1,1,N,\"Yo\"\nA13,26,0,1,1,1,N,\"ThisIsAnExtremelyLongWordThatWontFitOntoASingleLineOfTextButShouldPrintAnywayOkayThanksBye\"\nA13,52,0,1,1,1,N,\"yo\"\n", @label.output     
  end
  
  def test_should_wrap_multi_text
    @label.draw_multi_text("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
    assert_equal "\nN\nq776\nQ329\nZT\nA13,0,0,1,1,1,N,\"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do\"\nA13,26,0,1,1,1,N,\"eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad\"\nA13,52,0,1,1,1,N,\"minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip\"\nA13,78,0,1,1,1,N,\"ex ea commodo consequat. Duis aute irure dolor in reprehenderit in\"\nA13,104,0,1,1,1,N,\"voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur\"\nA13,130,0,1,1,1,N,\"sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt\"\nA13,156,0,1,1,1,N,\"mollit anim id est laborum.\"\n", @label.output     
  end
  
  def test_should_print_multi_text_with_new_lines
    # Pope
    @label.draw_multi_text("Where-e'er you find \"the cooling western breeze,\"\n"+
                           "In the next line, it \"whispers through the trees;\"\n"+
                           "If crystal streams \"with pleasing murmurs creep,\"\n"+
                           "The reader's threatened (not in vain) with \"sleep.\"")
    assert_equal "\nN\nq776\nQ329\nZT\nA13,0,0,1,1,1,N,\"Where-e'er you find \"the cooling western breeze,\"\"\nA13,26,0,1,1,1,N,\"In the next line, it \"whispers through the trees;\"\"\nA13,52,0,1,1,1,N,\"If crystal streams \"with pleasing murmurs creep,\"\"\nA13,78,0,1,1,1,N,\"The reader's threatened (not in vain) with \"sleep.\"\"\n", @label.output     
  end
  
  def test_should_wrap_to_next_column
    @label.column_width = 300
    @label.column_count = 2
    @label.column_spacing = 20
    @label.font_size = 4
    @label.draw_multi_text("1\n2\n3\n4\n5\n6\n7\n8\n")
    assert_equal "\nN\nq776\nQ329\nZT\nA13,0,0,4,1,1,N,\"1\"\nA13,50,0,4,1,1,N,\"2\"\nA13,100,0,4,1,1,N,\"3\"\nA13,150,0,4,1,1,N,\"4\"\nA13,200,0,4,1,1,N,\"5\"\nA13,250,0,4,1,1,N,\"6\"\nA333,0,0,4,1,1,N,\"7\"\nA333,50,0,4,1,1,N,\"8\"\n", @label.output     
  end
  
  def test_should_wrap_to_next_label  
    @label.column_width = 300
    @label.column_count = 1
    @label.column_spacing = 20
    @label.font_size = 4
    @label.draw_multi_text("1\n2\n3\n4\n5\n6\n7\n8\n9")
    assert_equal "\nN\nq776\nQ329\nZT\nA13,0,0,4,1,1,N,\"1\"\nA13,50,0,4,1,1,N,\"2\"\nA13,100,0,4,1,1,N,\"3\"\nA13,150,0,4,1,1,N,\"4\"\nA13,200,0,4,1,1,N,\"5\"\nA13,250,0,4,1,1,N,\"6\"\nP1\n\nN\nq776\nQ329\nZT\nA13,0,0,4,1,1,N,\"7\"\nA13,50,0,4,1,1,N,\"8\"\nA13,100,0,4,1,1,N,\"9\"\n", @label.output     
  end

  def test_should_get_char_size
  end  
  
  def test_should_maintain_position_between_multi_text_calls
    # Pope
    @label.draw_multi_text("Where-e'er you find \"the cooling western breeze,\"")
    @label.draw_multi_text("In the next line, it \"whispers through the trees;\"")
    @label.draw_multi_text("If crystal streams \"with pleasing murmurs creep,\"")
    @label.draw_multi_text("The reader's threatened (not in vain) with \"sleep.\"")
    assert_equal "\nN\nq776\nQ329\nZT\nA13,0,0,1,1,1,N,\"Where-e'er you find \"the cooling western breeze,\"\"\nA13,26,0,1,1,1,N,\"In the next line, it \"whispers through the trees;\"\"\nA13,52,0,1,1,1,N,\"If crystal streams \"with pleasing murmurs creep,\"\"\nA13,78,0,1,1,1,N,\"The reader's threatened (not in vain) with \"sleep.\"\"\n", @label.output     
  end
end
