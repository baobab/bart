class BasePdf < FPDF

  def initialize
    super('L', 'mm', 'A4')
    @column = 0
    @column_width = 65
    @column_count = 1
    @column_padding = 0
    @line_height = 5
    @top_padding = 0.5 * 25.4
    @left_padding = 0.5 * 25.4
    @portrait_page_width = 7.5 * 25.4
  end
  
  def display
  end

protected
  
  def grids(want_margin = true, want_grid = true)
    self.SetTextColor(0, 0, 0)
    self.SetLeftMargin(0)
    self.SetTopMargin(0)
    self.SetRightMargin(0)
    self.SetFont('Arial', '', 8)
    # Draw the grid in mm in steps of 10 and label
    if want_grid
      self.SetDrawColor(228, 228, 228)    
      (1..20).each {|x|
        self.SetXY(10*x, 10-3)
        self.MultiCell(10, 10, "#{10*x}", 0, 'L') 
        (1..25).each {|y|
          self.Rect(0, 0, 10*x, 10*y)
        }  
      }  
      (1..25).each {|y|
        self.SetXY(10, (10*y)-3)
        self.MultiCell(10, 10, "#{10*y}", 0, 'L') 
      }  
      self.SetDrawColor(0, 0, 0)    
    end  
  end
  
  def column_header(s, break_column = false, break_page = false) 
    if (break_page) 
      self.AddPage()    
      self.SetLeftMargin(0.5 * 25.4)
      self.SetTopMargin(0.5 * 25.4)
      self.SetRightMargin(0.5 * 25.4)
      self.SetAutoPageBreak(true, 25)
      self.column = 0    
    elsif (break_column) 
      self.column = @column + 1
    end
    self.SetFont('','B')
    self.MultiCell(@column_width, @line_height, s, 0, 'J')
  end
  
  def column_text(s) 
    self.SetFont('','')
    self.MultiCell(@column_width, @line_height, s, 0, 'J')
  end
  
  def column_count=(count)
    @column_count = count
    @column_width = (@portrait_page_width - @column_padding) / count if (count)
  end

  def column_width=(width)
    @column_width = width
  end
  
  def column_padding=(padding)
    @column_padding = padding
  end
  
  def top_padding=(padding)
    @top_padding = padding
  end
  
  def left_padding=(padding)
    @left_padding = padding
  end
  
  def line_height=(height)
    @line_height = height
  end

  def column=(col)  
    # Move position to a column
    @column = col
    x = @left_padding + (col * (@column_padding + @column_width))
    self.SetLeftMargin(x)
    self.SetX(x)
    self.SetY(@top_padding)
  end
  
  def AcceptPageBreak
    if (@column < @column_count - 1)
      # Go to the next column
      self.column = @column + 1
      return false
    else
      # Go back to the first column and issue a page break
      self.column = 0
      return true
    end
  end        

end