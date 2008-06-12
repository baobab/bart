# This example, when run, will generate a PDF file called example5.pdf.
# This is based directly on the fifth tutorial example given on the
# FPDF website (http://www.fpdf.org).

require 'fpdf'

class PDF < FPDF

    # Load data
    def LoadData(file)

	data = Array.new

	# Read file lines
	IO.foreach(file) {|line| data.push(line.chop.split(';'))}

	return data
    end

    # Simple table
    def BasicTable(header, data)

	# Header
	header.each do |col|
	    Cell(40, 7, col, 1)
	end

	Ln()

	# Data
	data.each do |row| 
	    row.each {|col| Cell(40, 6, col, 1)}
	    Ln()
	end
    end

    # Better table
    def ImprovedTable(header, data)

	# Column widths
	w = [40, 35, 40, 45]

	# Header
	0.upto(header.length - 1) do |i|
	    Cell(w[i], 7, header[i], 1, 0, 'C')
	end
	Ln()

	# Data
	data.each {|row|
	    Cell(w[0], 6, row[0], 'LR')
	    Cell(w[1], 6, row[1], 'LR')
	    Cell(w[2], 6, row[2].to_s.reverse.gsub(/\d{3}(?=\d)/, '\&,').reverse, 'LR', 0, 'R')
	    Cell(w[3], 6, row[3].to_s.reverse.gsub(/\d{3}(?=\d)/, '\&,').reverse, 'LR', 0, 'R')
	    Ln()
	}

	# Closure line
	sum = 0
	w.each {|a| sum += a}
	Cell(sum, 0, '', 'T')
    end

    # Colored table
    def FancyTable(header, data)

	# Colors, line width and bold font
	SetFillColor(255, 0, 0)
	SetTextColor(255)
	SetDrawColor(128, 0, 0)
	SetLineWidth(0.3)
	SetFont('', 'B')

	# Header
	w = [40.0, 35.0, 40.0, 45.0]
	0.upto(header.length - 1) do |i|
	    Cell(w[i], 7, header[i], 1, 0, 'C', 1)
	end
	Ln()

	# Color and font restoration
	SetFillColor(224, 235, 255)
	SetTextColor(0)
	SetFont('')

	# Data
	fill = 0

	data.each do |row|

	    Cell(w[0], 6, row[0], 'LR', 0, 'L', fill)
	    Cell(w[1], 6, row[1], 'LR', 0, 'L', fill)
	    Cell(w[2], 6, row[2].to_s.reverse.gsub(/\d{3}(?=\d)/, '\&,').reverse, 'LR', 0, 'R', fill)
	    Cell(w[3], 6, row[3].to_s.reverse.gsub(/\d{3}(?=\d)/, '\&,').reverse, 'LR', 0, 'R', fill)
	    Ln()
	    fill = (fill == 0 ? 1 : 0)
	end

	sum = 0
	w.each {|a| sum += a}
	Cell(sum, 0, '', 'T')
    end
end

pdf = PDF.new

# Column titles

header = ['Country', 'Capital', 'Area (sq km)', 'Pop. (thousands)']

# Data loading

data = pdf.LoadData('countries.txt')
pdf.SetFont('Helvetica', '', 14);
pdf.AddPage()
pdf.BasicTable(header, data)
pdf.AddPage()
pdf.ImprovedTable(header, data)
pdf.AddPage()
pdf.FancyTable(header, data)
pdf.Output('example5.pdf')
