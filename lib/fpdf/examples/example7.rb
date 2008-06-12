# This example, when run, will generate a PDF file called example7.pdf.
# This is based directly on the seventh tutorial example given on the
# FPDF website (http://www.fpdf.org).

require 'fpdf'

pdf=FPDF.new
pdf.AddFont('Calligrapher','','calligra.rb')
pdf.AddPage()
pdf.SetFont('Calligrapher','',35)
pdf.Cell(0,10,'Enjoy new fonts with FPDF!')
pdf.Output('example7.pdf')
