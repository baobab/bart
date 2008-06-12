# This example, when run, will generate a PDF file called example6.pdf.
# This is based directly on the sixth tutorial example given on the
# FPDF website (http://www.fpdf.org).

require 'fpdf'

class PDF < FPDF

    def initialize(orientation='P', unit='mm', format='A4')
	super(orientation, unit, format)

	@tags = { 'B' => false, 'I' => false, 'U' => false }
	@href = ''
    end

    def WriteHTML(html)
        # HTML parser
	html = html.gsub(/\n/, ' ')
        a = html.split(/<(.*?)>/, -1)
        a.each_index do |i|
            e = a[i]

            if i % 2 == 0 then
                # Text
                if @href != '' then
                    PutLink(@href, e)
                else
                    Write(5, e)
                end
            else
                # Tag
                if e[0, 1] == '/' then
                    CloseTag(e[1, e.length - 1].upcase)
                else
                    # Extract attributes
                    a2 = e.split(' ')
                    tag = a2.shift.upcase
                    attr = {}
                    a2.each do |v|
                        if a3 = /^([^=]*)=["\']?([^"\']*)["\']?$/.match(v) then
                            attr[a3[1].upcase] = a3[2]
                        end
                    end
                    OpenTag(tag,attr)
                end
            end
        end
    end

    def OpenTag(tag,attr)
	# Opening tag
        case tag
	when 'B', 'I', 'U'
            SetStyle(tag,true)
        when 'A' then
            @href = attr['HREF']
        when 'BR' then
            Ln(5)
        end
    end

    def CloseTag(tag)
        # Closing tag
        case tag
        when 'B', 'I', 'U' then
            SetStyle(tag,false)
        when 'A' then
            @href = ''
        end
    end

    def SetStyle(tag,enable)
        # Modify style and select corresponding font
        @tags[tag] = enable
        style = ''
        @tags.each do |tag, value|
            style += tag if value
        end
	SetFont('',style)
    end

    def PutLink(url,txt)
        # Put a hyperlink
        SetTextColor(0,0,255)
        SetStyle('U',true)
        Write(5,txt,url)
        SetStyle('U',false)
        SetTextColor(0)
    end
end

html='You can now easily print text mixing different
styles : <B>bold</B>, <I>italic</I>, <U>underlined</U>, or
<B><I><U>all at once</U></I></B>!<BR>You can also insert links
on text, such as <A HREF="http://www.fpdf.org">www.fpdf.org</A>,
or on an image: click on the logo.'

pdf = PDF.new
# First page
pdf.AddPage()
pdf.SetFont('Helvetica','',20)
pdf.Write(5,"To find out what's new in this tutorial, click ")
pdf.SetFont('','U')
link=pdf.AddLink()
pdf.Write(5,'here',link)
pdf.SetFont('')
# Second page
pdf.AddPage()
pdf.SetLink(link)
pdf.Image('logo.png',10,10,30,0,'','http://www.fpdf.org')
pdf.SetLeftMargin(45)
pdf.SetFontSize(14)
pdf.WriteHTML(html)
pdf.Output('example6.pdf')
