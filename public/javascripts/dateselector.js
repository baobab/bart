// --------------------------------------------------------------------
// 
// Touchscreen Toolkit
//
// (c) 2007 Baobab Health Partnership www.baobabhealth.org

//This library is free software; you can redistribute it and/or
//modify it under the terms of the GNU Lesser General Public
//License as published by the Free Software Foundation; either
//version 2.1 of the License, or (at your option) any later version.
//
//This library is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//Lesser General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public
//License along with this library; if not, write to the Free Software
//Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
//
// --------------------------------------------------------------------

var DateSelector = function() {
	this.date = new Date();
	if (! arguments[0]) 
		arguments[0] = {};
	
	this.options = {
		year: arguments[0].year || this.date.getFullYear(), 
		month: arguments[0].month || this.date.getMonth() + 1,
		date: arguments[0].date || this.date.getDate(),
		format: arguments[0].format || "dd/MM/yyyy",
		element: arguments[0].element || document.body,
		target: arguments[0].target
	};

	if (typeof(tstCurrentDate) != "undefined") {
		var splitDate = tstCurrentDate.split("/");
		if (splitDate.length == 3) {
			this.date = new Date(splitDate[0], splitDate[1]-1, splitDate[2]); 
		}
	}	else {
		this.date = new Date(this.options.year, this.options.month -1, this.options.date);
	}
	this.element = this.options.element;
	this.format = this.options.format;
	this.formatDate = this.format.length>0 ? DateUtil.simpleFormat(this.format) : DateUtil.toLocaleDateString;
	this.target = this.options.target;
	
	var dateElement = document.createElement('div');
	this.element.appendChild(this.build());

	this.currentYear = $('dateselector_year');
	this.currentMonth = $('dateselector_month');
	this.currentDay = $('dateselector_day');
	
	this.currentYear.value = this.date.getFullYear();
	this.currentMonth.value = this.getMonth();
	this.currentDay.value = this.date.getDate();
};

DateSelector.prototype = {
	build: function() {
		var node = document.createElement('div');
		// TODO: move style stuff to a css file
		node.innerHTML = ' \
			<div id="dateselector" class="dateselector"> \
			<table><tr> \
			<td valign="top"> \
			<div style="display: inline;" > \
				<button id="dateselector_nextYear" onmousedown="ds.incrementYear();">+</button> \
				<input id="dateselector_year" type="text" > \
				<button id="dateselector_preYear" onmousedown="ds.decrementYear();">-</button> \
			</div> \
			</td><td> \
			<div style="display: inline;"> \
				<button id="dateselector_nextMonth" onmousedown="ds.incrementMonth();">+</button> \
				<input id="dateselector_month" type="text"> \
				<button id="dateselector_preMonth" onmousedown="ds.decrementMonth();">-</button> \
			</div> \
			</td><td> \
			<div style="display: inline;"> \
				<button id="dateselector_nextDay" onmousedown="ds.incrementDay();">+</button> \
				<input id="dateselector_day" type="text"> \
				<button id="dateselector_preDay" onmousedown="ds.decrementDay();">-</button> \
			</div> \
			</td><td> \
			<button id="num" onmousedown="press(this.id);" style="width: 130px;">Num</button> \
			<button id="Unknown" onmousedown="press(this.id);" style="width: 130px;">Unknown</button> \
			</tr></table> \
			</div> \
		';
		
		return node;
	},

	getMonth: function() {
		return  DateUtil.months[this.date.getMonth()];
	},

	incrementYear: function() {
		this.currentYear.value++;
		this.date.setFullYear(this.currentYear.value);
		this.update(this.target);
	},
	
	decrementYear: function() {
		if (this.currentYear.value > 1)	{	// > minimum Year
			this.currentYear.value--;
			this.date.setFullYear(this.currentYear.value);
			this.update(this.target);
		}
	},
	
	incrementMonth: function() {
		if (this.date.getMonth() >= 11) {
			this.date.setMonth(0);
			this.currentMonth.value = this.getMonth();
		} else {
			var lastDate = DateUtil.getLastDate(this.date.getFullYear(), this.date.getMonth()+1).getDate();
			if (lastDate < this.date.getDate()) {
				this.currentDay.value = lastDate;
				this.date.setDate(lastDate);
			}
			
			this.date.setMonth(this.date.getMonth()+1);
			this.currentMonth.value = this.getMonth();
		}
		this.update(this.target);
	},
	
	decrementMonth: function() {
		var thisMonth = this.date.getMonth();
		if (thisMonth <= 0) {	
			this.date.setMonth(11)
			this.currentMonth.value = this.getMonth();
		} else {
			var lastDate = DateUtil.getLastDate(this.date.getFullYear(), this.date.getMonth()-1).getDate();
			if (lastDate < this.date.getDate()) {
				this.currentDay.value = lastDate;
				this.date.setDate(lastDate);
			}

			this.date.setMonth(thisMonth-1)
			this.currentMonth.value = this.getMonth();
		}
		this.update(this.target);
	},
	
	incrementDay: function() {
		var currentDate = new Date(this.date.getFullYear(), this.date.getMonth(), this.date.getDate());
		var nextDay = DateUtil.nextDate(currentDate);
		if (nextDay.getMonth() == this.date.getMonth()) 
			this.date.setDate(this.date.getDate()+1);
		else
			this.date.setDate(1);

		this.currentDay.value = this.date.getDate();
		this.update(this.target);
	},
	
	decrementDay: function() {
		if (this.currentDay.value > 1)
			this.currentDay.value--;
		else
			this.currentDay.value =DateUtil.getLastDate(this.date.getFullYear(), this.date.getMonth()).getDate();
			
		this.date.setDate(this.currentDay.value);
		this.update(this.target);
	},

	update: function(aDateElement) {
		var aTargetElement = aDateElement || this.target;
			
		if (!aTargetElement)
			return;

		aTargetElement.value = this.formatDate(this.date);
	}

};

/**
 * DateUtil
 */
var DateUtil = {

  dayOfWeek: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],

  months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],

  daysOfMonth: [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],

  isLeapYear: function(year) {
    if (((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0))
      return true;
    return false;
  }, 

  nextDate: function(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1);
  },

  previousDate: function(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() - 1);
  },
  
  getLastDate: function(year, month) {
    var last = this.daysOfMonth[month];
    if ((month == 1) && this.isLeapYear(year)) {
      return new Date(year, month, last + 1);
    }
    return new Date(year, month, last);
  },
  
  getFirstDate: function(year, month) {
    if (year.constructor == Date) {
      return new Date(year.getFullYear(), year.getMonth(), 1);
    }
    return new Date(year, month, 1);
  },

  getWeekTurn: function(date, firstDWeek) {
    var limit = 6 - firstDWeek + 1;
    var turn = 0;
    while (limit < date) {
      date -= 7;
      turn++;
    }
    return turn;
  },

  toDateString: function(date) {
    return date.toDateString();
  },
  
  toLocaleDateString: function(date) {
    return date.toLocaleDateString();
  },
  
  simpleFormat: function(formatStr) {
    return function(date) {
      var formated = formatStr.replace(/M+/g, DateUtil.zerofill((date.getMonth() + 1).toString(), 2));
      formated = formated.replace(/d+/g, DateUtil.zerofill(date.getDate().toString(), 2));
      formated = formated.replace(/y{4}/g, date.getFullYear());
      formated = formated.replace(/y{1,3}/g, new String(date.getFullYear()).substr(2));
      formated = formated.replace(/E+/g, DateUtil.dayOfWeek[date.getDay()]);
      
      return formated;
    }
  },

  zerofill: function(date,digit){
    var result = date;
    if(date.length < digit){
      var tmp = digit - date.length;
      for(i=0; i < tmp; i++){
        result = "0" + result;
      }
    }
    return result;
  }
}


