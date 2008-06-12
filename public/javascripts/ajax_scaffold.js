/*  
 AjaxScaffoldGenerator version 3.1.0
 (c) 2006 Richard White <rrwhite@gmail.com>
 
 AjaxScaffoldGenerator is freely distributable under the terms of an MIT-style license.
 
 For details, see the AjaxScaffoldGenerator web site: http://www.ajaxscaffold.com/
*/

/*
 * The following is a cross browser way to move around <tr> elements in a <table> or <tbody>
 */
 
var Abstract = new Object();
Abstract.Table = function() {};
Abstract.Table.prototype = {
  tagTest: function(element, tagName) {
    return $(element).tagName.toLowerCase() == tagName.toLowerCase();
  }		
};	

Abstract.TableRow = function() {};
Abstract.TableRow.prototype = Object.extend(new Abstract.Table(), {
  initialize: function(targetTableRow, sourceTableRow) {
    try {
      var sourceTableRow = $(sourceTableRow);
      var targetTableRow = $(targetTableRow);
      
      if (targetTableRow == null || !this.tagTest(targetTableRow,'tr') 
      	|| sourceTableRow == null || !this.tagTest(sourceTableRow,'tr')) {
        throw("TableRow: both parameters must be a <tr> tag.");
      }
      
      var tableOrTbody = this.findParentTableOrTbody(targetTableRow);
      
      var newRow = tableOrTbody.insertRow(this.getNewRowIndex(targetTableRow) - this.getRowOffset(tableOrTbody));
      newRow.parentNode.replaceChild(sourceTableRow, newRow);

    } catch (e) {
      alert(e);
    }
  },
  getRowOffset: function(tableOrTbody) {
    //If we are inserting into a tablebody we would need figure out the rowIndex of the first
    // row in that tbody and subtract that offset from the new row index  
    var rowOffset = 0;
    if (this.tagTest(tableOrTbody,'tbody')) {
      rowOffset = tableOrTbody.rows[0].rowIndex;
    }
    return rowOffset;
  },
  findParentTableOrTbody: function(element) {
    var element = $(element);
    // Completely arbitrary value
    var maxSearchDepth = 3;
    var currentSearchDepth = 1;
    var current = element;
    while (currentSearchDepth <= maxSearchDepth) {
      current = current.parentNode;
      if (this.tagTest(current, 'tbody') || this.tagTest(current, 'table')) {
        return current;
      }
      currentSearchDepth++;
    }
  }		
});

var TableRow = new Object();

TableRow.MoveBefore = Class.create();
TableRow.MoveBefore.prototype = Object.extend(new Abstract.TableRow(), {
  getNewRowIndex: function(target) {
    return target.rowIndex;
  }
});

TableRow.MoveAfter = Class.create();
TableRow.MoveAfter.prototype = Object.extend(new Abstract.TableRow(), {
  getNewRowIndex: function(target) {
    return target.rowIndex+1;
  }
});

/*
 * The following are simple utility methods
 */
 
var AjaxScaffold = {  
  stripe: function(tableBody) {
    var even = false;
    var tableBody = $(tableBody);
    var tableRows = tableBody.getElementsByTagName("tr");
    var length = tableBody.rows.length;
      
    for (var i = 0; i < length; i++) {
      var tableRow = tableBody.rows[i];
      //Make sure to skip rows that are create or edit rows or messages
      if (!Element.hasClassName(tableRow, "create") 
        && !Element.hasClassName(tableRow, "update")) {
      	
        if (even) {
          Element.addClassName(tableRow, "even");
        } else {
          Element.removeClassName(tableRow, "even");
        }
        even = !even;
      }
    }
  },
  displayMessageIfEmpty: function(tableBody, emptyMessageElement) {
    // Check to see if this was the last element in the list
    if ($(tableBody).rows.length == 0) {
      Element.show($(emptyMessageElement));
    }
  },
  removeSortClasses: function(scaffoldId) {
    $$('#' + scaffoldId + ' td.sorted').each(function(element) {
      Element.removeClassName(element, "sorted");
    });
    $$('#' + scaffoldId + ' th.sorted').each(function(element) {
      Element.removeClassName(element, "sorted");
      Element.removeClassName(element, "asc");
      Element.removeClassName(element, "desc");
    });
  }
}