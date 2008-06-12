DatePicker.prototype.buildExtraButtons = function() {	
	var extraButtons = document.createElement('div'); // don't add to keyboard.innerHTML directly
	extraButtons.innerHTML += getButtonString('num','<span>Num</span>');
	extraButtons.style.align="right"
	return extraButtons;
}

DatePicker.prototype.refresh = function() {
	Element.remove(this.calendar);
	this.element.innerHTML = "";
	this.calendar = this.build();
	this.element.appendChild(this.calendar);
	this.element.appendChild(this.buildExtraButtons());
}

// disable datepicker popup mode
DatePicker.prototype.hide = function() {
	this.refresh();
}
  
DatePicker.prototype.buildTableData = function() {
    var length = DateUtil.dayOfWeek.length * 5;
    var year = this.date.getFullYear();
    var month = this.date.getMonth();
    var firstDay = DateUtil.getFirstDate(year, month).getDay();
    var lastDate = DateUtil.getLastDate(year, month).getDate();

		var extraDays = lastDate - (length - firstDay);
    var trs = new Array();
    var tds = new Array();

		// for date highlighting
		var isDayOfMonthPicker = false;
		var railsDate = new RailsDate(this.target);
		if (railsDate.isDayOfMonthElement())
			isDayOfMonthPicker = true;
		
    
    for (var i = 0, day = 1; i <= length; i++) {
      //if ((i < firstDay) || day > lastDate) {
      if (((i < firstDay) || day > lastDate) && i >= extraDays) {
        tds.push(Builder.node('TD'));
      
      } else {
        var className;
        if ((i % 7 == 0) || ((i+1) % 7 == 0))
          className = 'holiday';
        else
          className = 'date';
          
        var defaultClass = this.classNames.joinClassNames(className);
				var nodeDay = day;
				if (i < extraDays) {
					nodeDay = (length-firstDay+i+1);
					node = Builder.node('TD', {className: defaultClass}, [nodeDay]);
				} else {
					node = Builder.node('TD', {className: defaultClass}, [day]);
					day++;
				}

				if (isDayOfMonthPicker && nodeDay == this.target.value)
					node.style.backgroundColor = '#D5DFE8'; 
					
				var currentDate = this.target.value.split('/');
				if (year == currentDate[2] && month == currentDate[1]-1 &&
						nodeDay == currentDate[0]) 
					node.style.backgroundColor = '#D5DFE8';
				
        new Hover(node);
        Event.observe(node, "click", this.selectDate.bindAsEventListener(this));
        tds.push(node);
      }
      if ((i + 1) % 7 == 0) {
        trs.push(Builder.node('TR', tds));
        tds = new Array();
      }
    }
    
    return trs;
}

DatePicker.prototype.buildHeaderLeft = function() {
	var container = Builder.node('TD');
	this.classNames.addClassNames(container, 'preYears');

	var id = this.element.id.appendSuffix('preMonthMark');
	var node = Builder.node('DIV', {id: id});

	var railsDate = new RailsDate(this.target);
	if (!railsDate.isDayOfMonthElement()) {
		this.classNames.addClassNames(node, 'preMonthMark');
		Event.observe(node, "click", this.changeCalendar.bindAsEventListener(this));
		node.innerHTML = "-"
		container.appendChild(node);
	}
	
	id = this.element.id.appendSuffix('nextMonth');
	node = Builder.node('DIV', {id: id}, [DateUtil.months[this.date.getMonth()]]);
	this.classNames.addClassNames(node, 'ym');
	container.appendChild(node);

	if (!railsDate.isDayOfMonthElement()) {
		id = this.element.id.appendSuffix('nextMonthMark');
		node = Builder.node('DIV', {id: id});
		this.classNames.addClassNames(node, 'nextMonthMark');
		Event.observe(node, "click", this.changeCalendar.bindAsEventListener(this));
		node.innerHTML = " + "
		container.appendChild(node);
	}
	return container;
}

DatePicker.prototype.buildHeaderCenter = function() {
	return Builder.node('DIV');
}

DatePicker.prototype.buildHeaderRight = function() {
	var container = Builder.node('TD');
	this.classNames.addClassNames(container, 'nextYears');

	var id;
	var node;

	var railsDate = new RailsDate(this.target);
	if (!railsDate.isDayOfMonthElement()) {
		id = this.element.id.appendSuffix('preYearMark');
		node = Builder.node('DIV', {id: id});
		this.classNames.addClassNames(node, 'preYearMark');
		Event.observe(node, "click", this.changeCalendar.bindAsEventListener(this));
		node.innerHTML = "-"
		container.appendChild(node);
	}

	id = this.element.id.appendSuffix('nextYear');
	node = Builder.node('DIV', {id: id}, [this.date.getFullYear()]);
	this.classNames.addClassNames(node, 'ym');
	container.appendChild(node);

	if (!railsDate.isDayOfMonthElement()) {
		id = this.element.id.appendSuffix('nextYearMark');
		node = Builder.node('DIV', {id: id});
		this.classNames.addClassNames(node, 'nextYearMark');
		Event.observe(node, "click", this.changeCalendar.bindAsEventListener(this));
		node.innerHTML = " + "
		container.appendChild(node);
	}

	return container;
}
