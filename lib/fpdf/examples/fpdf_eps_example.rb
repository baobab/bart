require 'fpdf'
require 'fpdf_eps'

pdf = FPDF.new
pdf.extend(PDF_EPS)

pdf.AddPage()
pdf.SetFont('Arial','B',30)
pdf.Cell(50,14,'FPDF with EPS support works!!')
pdf.ImageEps('bug.eps',14,30,50)
pdf.Output('fpdf_eps_example.pdf')
