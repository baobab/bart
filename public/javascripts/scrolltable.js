//
// Scrollable Tables Version 2.0
// =============================
//
// This javascript file can be included in any HTML document that 
// contains data tables.  It will convert excessively long tables
// into smaller tables that are scrollable.  
//
// To use it, simply include the Javascript in your document and 
// run `setupLongTables()` in the onload event of the <body> tag.
//
// Two parameters are used to control the detection of an excessively
// long table, and the number of rows to be displayed in a converted
// table: long_table_length and batch_size.  These can be hard-coded
// below or added to the URL as parameters.
//
// Examples::
//     http://www.foo.com/mytables.html?batch_size=3
//     http://www.foo.com/mytables.html?batch_size=3&long_table_length=20
//
// You can also have a table displayed at a particular row when the 
// file is loaded.  This is done through the hash (i.e. #) portion of
// the URL.  There are several ways to invoke this: row number 
// (e.g. #row6), ID of a row (e.g. #rowid-foo), table number with row 
// number (e.g. #table2-row5), and table ID with row number 
// (e.g. #tableid-foo-row3).  Table and row numbers start with 1.
//
// Examples::
//     # Start at row 6 in all tables
//     http://www.foo.com/mytables.html#row6
//     # Start at row 6 in table 4
//     http://www.foo.com/mytables.html#table4-row6
//     # Start at row 5 in table with id="bar"
//     http://www.foo.com/mytables.html#tableid-bar-row5
//     # Start at row with id="bar"
//     http://www.foo.com/mytables.html#rowid-bar
//
// You can modify the how the navigation components look by editting the
// variable `TableSkin`.  This variable is simply a fragment of HTML.
// You must preserve the IDs in the default skin.  Those IDs are used
// to set up the onclick events, but everything else is completely
// customizable.
//
// This code should work in any browser that supports DOM (i.e. MSIE 5.5+,
// Safari, Mozilla, etc.).
//
// Known Issues
// ------------
//
// Some browsers have issues with code that messes with already rendered
// table structures.  You may see some artifacts of this in table
// borders while scrolling a table.
//
// The anchor (i.e. #) operation only works when the page is first loaded.
// If you change the URL, you have to do a reload to get the table to
// expand at the right point the second time.  Also, Internet Explorer
// doesn't seem to handle the ID versions of anchors.
//
// Changes from Version 1.0
// ------------------------
//
// Complete rewrite using object oriented techniques, IDs for addressing
// rows and tables to increase performance, and skins to allow user
// customization of the navigation panel.  Also, added the anchor (i.e. #)
// handler.
//
// Bugs/Comments: Kevin.Smith@sas.com
//

// Number of rows to show in each batch of the table
var batch_size = 5;

// Minimum length of table before batching should occur
// var long_table_length = (2*batch_size)+1;
   var long_table_length = 5;

// Markup to use for navigation components.  The data table will be
// inserted into the element with ID "datatable".
var TableSkin = '\
<div id="navigation"> \
<table> \
<tr> \
<td id="datatable"></td> \
<td> \
<table style="text-align:center"> \
<tr><td class="up" id="up"><IMG SRC="/images/up.gif"></td></tr> \
<tr><td class="rowstatus" id="rowstatus" style="font-size:small; height:90px"></td></tr> \
<tr><td class="down" id="down"><IMG SRC="/images/down.gif"></td></tr> \
</table> \
</td> \
</tr> \
</table> \
</div> \
'

var Tables = [];

// See if the batch_size and long_table_length have been overridden
// in the URL variables
/* var qs = location.search.substring(1);
var nv = qs.split('&');
var url = new Object();
var options = 0;
for (var i = 0; i < nv.length; i++)
{
    var part = nv[i];
    eq = part.indexOf('=');
    key = part.substring(0,eq).toLowerCase();
    value = unescape(part.substring(eq+1));
    if (key == 'batch_size')
    {
        batch_size = parseInt(value);
        options |= 1;
    }
    else if (key == 'long_table_length')
    {
        long_table_length = parseInt(value);
        options |= 2;
    }
}
if ( (options & 1) && !(options & 2) )
    long_table_length = (2*batch_size)+1;  */

function getHash()
{
    var hash = location.hash;
    var table = 0;
    var row = 1;
    var rowid = '';
    var tableid = '';

    if ( !hash ) return [table, tableid, row, rowid];

    if ( hash.match(/^#tableid-.*-row\d+$/) ) 
    {
        var parts = hash.substring(9).split('-row');
        tableid = parts[0];
        row = parseInt(parts[1]);
    }
    else if ( hash.match(/^#row\d+$/) ) 
    {
        row = parseInt(hash.substring(4));
    }
    else if ( hash.match(/^#table\d+-row\d+$/) )
    {
        var parts = hash.substring(6).split('-row');
        table = parseInt(parts[0]);
        row = parseInt(parts[1]);
    }
    else if ( hash.match(/^#rowid-/) ) 
    {
        rowid = hash.substring(7);
    } 

    return [table, tableid, row, rowid];
}

function Table(elem)
//
// Instantiate a scrolling table
//
{
    if ( !elem ) return;
    this.name = 'table' + (Tables.length + 1);
    this.toprow = 0;
    this.rows = [];

    // If we have a nested table, bail out.  This probably isn't a data table
    if ( elem.getElementsByTagName('table').length )
        return;

    // See if we need to start at something other than the top of the table
    var anchor = getHash();
    var rowid = anchor[3];
    var tableid = anchor[1];
    if ( anchor[0] && anchor[0] == (Tables.length+1) )
        this.toprow = anchor[2] - 1;
    if ( !anchor[0] )
        this.toprow = anchor[2] - 1; 
    if ( tableid && elem.getAttribute('id') != tableid )
        this.toprow = 0;
    if ( rowid ) rowid = document.getElementById(rowid)

    // Give each row a unique id
    var tbody = elem.getElementsByTagName('tbody');

    // Make sure that the table is long enough for scrolling
    // and build the list of rows while we're here.
    for (var i = 0; i < tbody.length; i++)
    {
        var rows = tbody[i].getElementsByTagName('tr');
        for (var j = 0; j < rows.length; j++ )
        {
            this.rows[this.rows.length] = rows[j];
            if ( rowid && rowid === rows[j] )
                this.toprow = this.rows.length - 1;
        }
    }
    if ( this.rows.length <= long_table_length )
        return;

    // Reality check on the top row value
    if ( (this.rows.length - this.toprow) < batch_size )
        this.toprow = this.rows.length - batch_size;  
    if ( this.toprow < 0 )
        this.toprow = 0;

    // Initialize rows
    for (var i = 0; i < this.rows.length; i++ )
    {
       if ( i >= this.toprow && (i - this.toprow) < batch_size )
           this.rows[i].style.display = '';
       else
           this.rows[i].style.display = 'none';
    }

    // Add this table to the list of tables
    Tables[this.name] = this;

    // Load navigation skin and make all ids unique to this table
    var text = TableSkin.replace(/(\bid=")([^"]+)"/g, '$1$2-' + this.name + '" onclick="javascript:event$2(\'' + this.name + '\')"');
    var nav = createElementFromString(text);

    // Swap table and navigation
    var child = elem.parentNode.replaceChild(nav, elem);
    document.getElementById('datatable-' + this.name).appendChild(child);

    this.updateStatus();
}

new Table();

Table.prototype.down = function()
//
// Scroll down one row
//
{
    if ( (this.toprow + batch_size) >= this.rows.length )
        return;
    this.rows[this.toprow].style.display = 'none';
    this.rows[this.toprow + batch_size].style.display = '';
    this.toprow++;
    this.updateStatus();
}

Table.prototype.up = function()
//
// Scroll up one row
//
{
    if ( this.toprow < 1 )
        return;
    this.toprow--;
    this.rows[this.toprow + batch_size].style.display = 'none';
    this.rows[this.toprow].style.display = '';
    this.updateStatus();
}

Table.prototype.pagedown = function()
//
// Scroll down by `batch_size`
//
{
    if ( (this.toprow + batch_size) >= this.rows.length )
        return;
    for (var i = 0; i < batch_size; i++)
        this.rows[this.toprow + i].style.display = 'none';
    this.toprow += batch_size - 1;
    if ( (this.toprow + batch_size) >= this.rows.length )
        this.toprow = this.rows.length - batch_size;
    for (var i = 0; i < batch_size; i++)
        this.rows[this.toprow + i].style.display = '';
    this.updateStatus();
}

Table.prototype.pageup = function()
//
// Scroll up by `batch_size`
//
{
    if ( this.toprow < 1 )
        return;
    for (var i = 0; i < batch_size; i++)
        this.rows[this.toprow + i].style.display = 'none';
    this.toprow -= batch_size - 1;
    if ( this.toprow < 1 )
        this.toprow = 0; 
    for (var i = 0; i < batch_size; i++)
        this.rows[this.toprow + i].style.display = '';
    this.updateStatus();
}

Table.prototype.top = function()
//
// Scroll to the top of the table
//
{
    if ( this.toprow == 0 )
        return;
    for ( i = 0; i < batch_size; i++ )
        this.rows[this.toprow + i].style.display = 'none';
    for ( i = 0; i < batch_size; i++ )
        this.rows[i].style.display = '';
    this.toprow = 0;
    this.updateStatus();
}

Table.prototype.bottom = function()
//
// Scroll to the bottom of the table
//
{
    if ( (this.toprow + batch_size) == this.rows.length )
        return;
    for ( i = batch_size; i > 0; i-- )
        this.rows[this.toprow + i - 1].style.display = 'none';
    for ( i = batch_size; i > 0; i-- )
        this.rows[this.rows.length - i].style.display = '';
    this.toprow = this.rows.length - batch_size;
    this.updateStatus();
}

Table.prototype.updateStatus = function()
//
// Update the displayed row status
//
{
    var elem = document.getElementById('rowstatus-' + this.name);
    elem.innerHTML = (this.toprow+1) + '-' + (this.toprow+batch_size) + '<br>of<br>' + this.rows.length;
}

function createElementFromString(str) 
//
// Compile an HTML string into a DOM element
//
{
    node = document.createElement('span');
    node.innerHTML = str;
    return node;
}

// Event handlers
function eventtop(name) { Tables[name].top() }
function eventpageup(name) { Tables[name].pageup() }
function eventup(name) { Tables[name].up() }
function eventdown(name) { Tables[name].down() }
function eventpagedown(name) { Tables[name].pagedown() }
function eventbottom(name) { Tables[name].bottom() }
function eventnavigation(name) {}
function eventrowstatus(name) {}

function setupLongTables()
//
// Locate all tables and create scrolling instances of thems
//
{
    if ( long_table_length < 0 )
        return;

    var tables = document.getElementsByTagName('table');
    var mytables = [];
    for (var i = 0; i < tables.length; i++ )
         mytables[mytables.length] = tables[1];  // hard coded to table one
    for (var i = 0; i < mytables.length; i++ )
        new Table(tables[1]); // hard coded to table one only
}
