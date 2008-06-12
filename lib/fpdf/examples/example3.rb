# This example, when run, will generate a PDF file called example3.pdf.
# This is based directly on the third tutorial example given on the
# FPDF website (http://www.fpdf.org).

require 'fpdf'

class PDF < FPDF

    def Header

	# Helvetica bold 15
	SetFont('Helvetica', 'B', 15)

	# Calculate width of title and position
	w = GetStringWidth($title) + 6
	SetX((210 - w) / 2)

	# Colors of frame, background and text
	SetDrawColor(0, 80, 180)
	SetFillColor(230, 230, 0)
	SetTextColor(220, 50, 50)

	# Thickness of frame (1 mm)
	SetLineWidth(1)

	# Title
	Cell(w, 9, $title, 1, 1, 'C', 1)

	# Line break
	Ln(10)
    end

    def Footer

	# Position at 1.5 cm from bottom
	SetY(-15)

	# Helvetica italic 8
	SetFont('Helvetica', 'I', 8)

	# Text color in gray
	SetTextColor(128)

	# Page number
	Cell(0, 10, 'Page '+ PageNo().to_s , 0, 0, 'C')
    end

    def ChapterTitle(num, label)

	# Helvetica 12
	SetFont('Helvetica', '', 12)

	# Background color
	SetFillColor(200, 220, 255)

	# Title
	Cell(0, 6, "Chapter #{num} : #{label}", 0, 1, 'L', 1)

	# Line break
	Ln(4)
    end

    def ChapterBody(file)

	# Read text file
	txt = IO.read(file)

	# Times 12
	SetFont('Times', '', 12)

	# Output justified text
	MultiCell(0, 5, txt)

	# Line break
	Ln()

	# Mention in italics
	SetFont('', 'I')
	Cell(0, 5, '(end of excerpt)');
    end

    def PrintChapter(num, title, file)

	AddPage()
	ChapterTitle(num, title)
	ChapterBody(file)

    end

end


pdf= PDF.new
$title='20000 Leagues Under the Seas'
pdf.SetTitle($title)
pdf.SetAuthor('Jules Verne')
pdf.PrintChapter(1, 'A RUNAWAY REEF', '20k_c1.txt')
pdf.PrintChapter(2, 'THE PROS AND CONS', '20k_c2.txt')
pdf.Output('example3.pdf')
