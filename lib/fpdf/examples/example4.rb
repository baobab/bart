# This example, when run, will generate a PDF file called example4.pdf.
# This is based directly on the fourth tutorial example given on the
# FPDF website (http://www.fpdf.org).

require 'fpdf'

class PDF < FPDF

    def initialize(orientation='P', unit='mm', format='A4')
	super(orientation, unit, format)

	@col = 0 # Current column
	@y0  = 0 # Ordinate of column start
    end

    def Header()

	# Page header

	SetFont('Helvetica', 'B', 15)
	w = GetStringWidth($title) + 6
	SetX((210 - w) / 2)
	SetDrawColor(0, 80, 180)
	SetFillColor(230, 230, 0)
	SetTextColor(220, 50, 50)
	SetLineWidth(1)
	Cell(w, 9, $title, 1, 1, 'C', 1)
	Ln(10)

	# Save ordinate
	@y0 = GetY()
    end

    def Footer()

	# Page footer
	SetY(-15)
	SetFont('Helvetica', 'I', 8)
	SetTextColor(128)
	Cell(0, 10, 'Page ' + PageNo().to_s, 0, 0, 'C')
    end

    def SetCol(col)

	# Set position at a given column
	@col = col
	x    = 10 + col * 65

	SetLeftMargin(x)
	SetX(x)
    end

    def AcceptPageBreak()

	# Method accepting or not automatic page break
	if @col < 2 then

	    # Go to next column
	    SetCol(@col + 1)

	    # Set ordinate to top
	    SetY(@y0)

	    # Keep on page
	    return false
	else

	    # Go back to first column
	    SetCol(0)

	    # Page break
	    return true
	end
    end

    def ChapterTitle(num, label)

	# Title
	SetFont('Helvetica', '', 12)
	SetFillColor(200, 220, 255)
	Cell(0, 6, "Chapter  #{num} : #{label}", 0, 1, 'L', 1)
	Ln(4)

	# Save ordinate
	@y0 = GetY()
    end

    def ChapterBody(fichier)

	# Read text file
	txt = IO.read(fichier)

	# Font
	SetFont('Times', '', 12)

	# Output text in a 6 cm width column
	MultiCell(60, 5, txt)
	Ln()

	# Mention
	SetFont('', 'I')
	Cell(0, 5, '(end of excerpt)')

	# Go back to first column
	SetCol(0)
    end

    def PrintChapter(num, title, file)

	# Add chapter
	AddPage()
	ChapterTitle(num, title)
	ChapterBody(file)
    end
end


pdf = PDF.new
$title='20000 Leagues Under the Seas';
pdf.SetTitle($title)
pdf.SetAuthor('Jules Verne')
pdf.PrintChapter(1, 'A RUNAWAY REEF', '20k_c1.txt')
pdf.PrintChapter(2, 'THE PROS AND CONS', '20k_c2.txt')
pdf.Output('example4.pdf')
