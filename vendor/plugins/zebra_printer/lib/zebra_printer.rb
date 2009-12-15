
## TODO: add text processing logic to escape characters outside of [A-Za-z0-9], consider :, \", (, ), \,
## TODO: add text processing logic to escape apostrophes
## TODO: maintain current x and current y throughout a label process

module ZebraPrinter #:nodoc:

  class Label 

    attr_reader :output
    attr_accessor :template
    attr_accessor :width, :height
    attr_accessor :orientation
    attr_accessor :left_margin, :right_margin, :top_margin, :bottom_margin
    attr_accessor :line_spacing
    attr_accessor :content_width, :content_height
    attr_accessor :column, :column_count, :column_width, :column_height, :column_spacing
    attr_accessor :x, :y
    attr_accessor :font_size, :font_horizontal_multiplier, :font_vertical_multiplier, :font_reverse
    attr_accessor :number_of_labels
 
    # Initialize a new label with height weight and orientation. The orientation
    # can be 'T' for top, or 'B' for bottom
    def initialize(width = 801, height = 329, orientation = 'T', number_of_labels = nil)
      @width = width || 801
      @height = height || 329
      @gap = '026'
      @orientation = orientation || 'T'
      @number_of_labels = number_of_labels || nil
      @left_margin = 35
      @right_margin = 25
      @top_margin = 30
      @bottom_margin = 26
      @line_spacing = 6
      @column_count = 1
      @content_width = @width - (@left_margin + @right_margin)
      @content_height = @height - (@top_margin + @bottom_margin)
      @column_width = @content_width
      @column_height = @content_height
      @column_spacing = 0
      @font_size = 1
      @font_horizontal_multiplier = 1
      @font_vertical_multiplier = 1
      @font_reverse = false
      @output = ""
      header
    end
    
    # Create a new label from a template (hash)
    def self.from_template(params, values = nil)
      label = Label.new(params[:width], params[:height], params[:orientation]) 
      (params[:fields] || []).each {|field|
        label.draw_text(field[:text] || field[:sample],
                        field[:left],
                        field[:top],
                        field[:rotation],
                        field[:font_size],
                        field[:font_horizontal_multiplier],
                        field[:font_vertical_multiplier],
                        field[:font_reverse])
      }                  
      (params[:lines] || []).each {|line|
        label.draw_line(line[:left],
                        line[:top],
                        line[:width],
                        line[:height],
                        line[:color])
      }                  
      (params[:frames] || []).each {|frame|
        label.draw_frame(frame[:left],
                         frame[:top],
                         frame[:width],
                         frame[:height],
                         frame[:frame_width])
      }                  
      (params[:barcodes] || []).each {|barcode|
        label.draw_barcode(barcode[:left],
                           barcode[:top],
                           barcode[:rotation],
                           barcode[:format],
                           barcode[:narrow_bar_width],
                           barcode[:wide_bar_width],
                           barcode[:height],
                           barcode[:human_readable],
                           barcode[:data])
      }                  
      label.template = params
      label
    end
    
    # Prints an initial header
    def header
      @x = @left_margin
      @y = @top_margin
      @column = 0
      @output << "\nN\n"       
      @output << "q#{@width}\n"      
      @output << "Q#{@height}#{',' unless @gap.blank?}#{@gap}\n"
      @output << "Z#{@orientation}\n"        
    end

    # Append the final print command to the label and return the output
    def print(label_sets = 1, label_copies = nil)
      label_sets = @number_of_labels unless @number_of_labels.blank?
      @output << "P#{label_sets}"
      @output << ",#{label_copies}" if label_copies
      @output << "\n"
      #@output << "N\\f\n\n"
      @output
    end
    
    # Issue a reset printer command, which has the same effect as turning the 
    # printer off and on
    def reset_printer
      @output << "^@\n"
      @output
    end

    # Draw a barcode:
    #  +x+ horizontal position
    #  +y+ vertical position
    #  +r+ rotation 1=90, 2=180, 3=270, 0=0
    #  +barcode_kind+ 1=code 128 A,B,C modes (see p. 51 EPL commands)
    #  +narrow_bar_width+ use 5
    #  +wide_bar_width+ use 15
    #  +h+ height of the barcode
    #  +print_code+ true/false, whether or not the human readable code should be printed
    def draw_barcode(x,y,r,barcode_kind,narrow_bar_width,wide_bar_width,h,print_code,data)      
      @output << "B#{x},#{y},#{r},#{barcode_kind},#{narrow_bar_width},#{wide_bar_width},#{h},#{print_code ? 'B' : 'N'},\"#{data}\"\n"
    end
    
    # Draw line
    # +color+ 0=black, 1=white, 2=xor
    def draw_line(x,y,w,h,color = 0)
      case color
        when 1 
          @output << "LW"
        when 2
          @output << "LE"
        else
          @output << "LO"
      end
      @output << "#{x},#{y},#{w},#{h}\n"
    end

    # Draw diagonal line
    def draw_line_diagonal(x,y,w,h,y2)
      @output << "LS#{x},#{y},#{w},#{h},#{y2}\n"
    end
    
    # Draw a frame
    def draw_frame(x,y,x2,y2,frame_width)
      @output << "X#{x},#{y},#{frame_width},#{x2},#{y2}\n"
    end
    
    # Draw text
    #  +data+ The actual text, escape characters with "\"     
    #  +x+ horizontal position
    #  +y+ vertical position
    #  +r+ rotation 1=90, 2=180, 3=270, 0=0
    #  +font_selection+ 
    #   Fonts are monospaced in general, for 203 dpi:
    #     1= 6pts (8 x 12 dots) -> actually this is 10 x 14 dots
    #     2= 7pts (10 x 16 dots) -> actually this is 12 x 20 dots
    #     3= 10pts (12 x 20 dots) -> actually this is 14 x 24 dots
    #     4= 12pts (14 x 24 dots) -> actually this is 16 x 32 dots
    #     5= 24pts (32 x 48 dots) -> actually this is 36.25 x 48 dots
    #     6= Numeric only (14 x 19 dots)
    #     7= Numeric only (14 x 19 dots)
    #
    #   For 300 dpi:
    #     1= 4pts (12 x 20 dots)
    #     2= 6pts (16 x 28 dots)
    #     3= 8pts (20 x 36 dots)
    #     4= 10pts (24 x 44 dots)
    #     5= 21pts (48 x 80 dots)
    #     6= Numeric only (14 x 19 dots)
    #     7= Numeric only (14 x 19 dots)
    #
    #  +horizontal_multiplier+ expand the text horizontally (valid values 1-9)
    #  +vertical_multiplier+ expand the text vertically (valid values 1-9)
    #  +reverse+ true/false, whether the text should be reversed
    def draw_text(data,x,y,r = 0,font_selection = 1,horizontal_multiplier = 1,vertical_multiplier = 1,reverse = false)
      data = data.gsub("'", "\\\\'")
      @output << "A#{x},#{y},#{r},#{font_selection},#{horizontal_multiplier},#{vertical_multiplier},#{reverse ? 'R' : 'N'},\"#{data}\"\n"          
    end    
    
    # Word wrapping, column wrapping, label wrapping text code, see draw_text for more information
    def draw_multi_text(data , options = {})
      data = data.gsub("'", "\\\\'")
      @font_size = options[:font_size] unless options[:font_size].nil?
      @font_horizontal_multiplier = options[:font_horizontal_multiplier] unless options[:font_horizontal_multiplier].nil?
      @font_vertical_multiplier = options[:font_vertical_multiplier] unless options[:font_vertical_multiplier].nil?
      @font_reverse = options[:font_reverse] unless options[:font_reverse].nil?
      @char_width, @char_height = get_char_sizes(@font_size, @font_horizontal_multiplier, @font_vertical_multiplier)
      @hanging_indent = options[:hanging_indent] || 0
      # Print each line separately
      data.split("\n").each {|line|
        next if line.blank?
        words = line.split("\s")        
        size = 0
        word_start_index = 0
        word_count = 0
        new_line = true 
        need_hanging_indent = false
        while word_start_index + word_count < words.size 
          next_word = word_start_index + word_count
          next_word_size = get_word_size(@char_width, words[next_word], !new_line)
          # Check if we need to wrap
          if (size + next_word_size >= @column_width)
            # Break the line, write what we have and continue 
            text = (need_hanging_indent ? ' ' * @hanging_indent : '') + words[word_start_index..(word_start_index + (word_count-1))].join(" ")
            check_bounds
            draw_text(text, @x, @y, 0, @font_size, @font_horizontal_multiplier, @font_vertical_multiplier, @font_reverse)
            # Allow for indents
            need_hanging_indent = true
            # Start from this word, count it and its size
            word_start_index = next_word 
            # Account for writing a single, really long word
            word_start_index += 1 if word_count == 0 
            word_count = 1
            size = next_word_size
            @y += @line_spacing + @char_height
            new_line = true
          else
            size += next_word_size
            word_count += 1
            new_line = false
          end  
        end    
        # Write out the end of the current set of words, should be DRYYYYYY
        unless word_start_index > words.size - 1
          text = (need_hanging_indent ? ' ' * @hanging_indent : '') + words[word_start_index..(word_start_index + (word_count-1))].join(" ")
          check_bounds
          draw_text(text, @x, @y, 0, @font_size, @font_horizontal_multiplier, @font_vertical_multiplier, @font_reverse)
        end  
        @y += @line_spacing + @char_height
      }                          
    end

  private
    
    def check_bounds
      # If we have run out of room, move to the next column
      if (@y + @char_height > @height - @bottom_margin)
        @column += 1              
        @y = @top_margin
        # If we have run out of columns, move to the next label
        if @column > @column_count - 1 
          @column = 0 
          print(1)
          header
        end  
        @x = @left_margin + (@column * (@column_width + @column_spacing))
      end                  
    end
    
    def get_char_sizes(font_selection, horizontal_multiplier, vertical_multiplier)
      case font_selection
        when 2
          char_width = 12
          char_height = 20
        when 3
          char_width = 14
          char_height = 24
        when 4
          char_width = 16
          char_height = 32
        when 5
          char_width = 36.25
          char_height = 48
        else
          char_width = 10
          char_height = 14        
      end
      return [char_width * horizontal_multiplier, char_height * vertical_multiplier]    
    end
  
    def get_word_size(char_width, word, need_space)
      (char_width * (word.size + (need_space ? 1 : 0))).to_i
    end
  end

  class StandardLabel < Label  
    def initialize()
      dimensions = (GlobalProperty.find_by_property("label_width_height").property_value rescue nil || "801,329").split(",").collect{|d|d.to_i}
      super(dimensions.first, dimensions.last, 'T')
    end  
  end
  
  
end
