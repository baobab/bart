# This example, when run, will generate a PDF file called example2.pdf.
# This is based directly on the second tutorial example given on the
# FPDF website (http://www.fpdf.org).

require 'fpdf'

class PDF < FPDF

    # Page header

    def Header
	# Logo
	Image('logo_pb.png', 10, 8, 33)

	# Helvetica bold 15
	SetFont('Helvetica', 'B', 15)

	# Move to the right
	Cell(80)

	# Title
	Cell(30, 10, 'Title', 1, 0, 'C')

	# Line break
	Ln(20)
    end

    # Page footer

    def Footer
	# Position at 1.5 cm from bottom
	SetY(-15)

	# Helvetica italic 8
	SetFont('Helvetica', 'I', 8)

	# Page number
	Cell(0, 10, 'Page ' + PageNo().to_s + '/{nb}', 0, 0, 'C')
    end
end

pdf=PDF.new
pdf.AliasNbPages
pdf.AddPage
pdf.SetFont('Times', '', 12)
for i in 0...40
    pdf.Cell(0, 10, 'Printing line number ' + i.to_s, 0, 1)
end
pdf.Output('example2.pdf')
