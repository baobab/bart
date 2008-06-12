module ZebraPrinter #:nodoc:
  class DebugLabel < Label 

    def initialize(width = 801, height = 329, orientation = 'T')
      super
      draw_numeric
    end
    
    def draw_numeric
      draw_multi_text(' 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9', {:font_size => 1, :hanging_indent => 6})
      draw_multi_text(' 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9', {:font_size => 2, :hanging_indent => 6})
      draw_multi_text(' 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9', {:font_size => 3, :hanging_indent => 6})
      draw_multi_text(' 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9', {:font_size => 4, :hanging_indent => 6})
      draw_multi_text(' 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9', {:font_size => 4, :hanging_indent => 6})
      draw_multi_text(' 1 3 5 7 9 1 3 5 7 9 1 3 5 7 9', {:font_size => 5, :hanging_indent => 6})
    end
    
  end  
      
end
