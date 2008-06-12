# This example, when run, will generate a PDF file called example.pdf.
# This is based directly on the first tutorial example given on the
# FPDF website (http://www.fpdf.org).

require 'fpdf'

pdf=FPDF.new
pdf.AddPage
pdf.SetFont('Arial','B',16)
pdf.Cell(40,10,'Hello World!')
pdf.Output('example1.pdf')
