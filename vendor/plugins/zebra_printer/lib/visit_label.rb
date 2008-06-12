
## TODO: add text processing logic to escape characters outside of [A-Za-z0-9], consider :, \", (, ), \,
## TODO: add text processing logic to escape apostrophes
## TODO: maintain current x and current y throughout a label process

module ZebraPrinter #:nodoc:

  class VisitLabel < Label 

    def initialize()
      @width = 776
      @height = 329
      @orientation = orientation || 'T'
      @left_margin = 13
      @right_margin = 13
      @top_margin = 13
      @bottom_margin = 26
      @line_spacing = 0
      @column_count = 1
      @content_width = @width - (@left_margin + @right_margin)
      @content_height = @height - (@top_margin + @bottom_margin)
      @column_width = @content_width
      @column_height = @content_height
      @column_spacing = 0
      @font_size = 3
      @font_horizontal_multiplier = 1
      @font_vertical_multiplier = 1
      @font_reverse = false
      @output = ""
      header
    end
    
    def self.from_encounters(encounters)
      label = VisitLabel.new
      encounters.each {|encounter| label.draw_encounter(encounter)}
      label
    end
    
    def draw_encounter(encounter)
      draw_multi_text(encounter.type.name, {:font_reverse => true})
      draw_multi_text(encounter.observations.collect{|obs| obs.to_short_s}.join(", "), {:font_reverse => false})
    end
  
  end  
      
end
