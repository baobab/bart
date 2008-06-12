// Copyright (c) 2005 spinelz.org (http://script.spinelz.org/)
// 
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

var DatePicker = Class.create();
DatePicker.className = {
  container: 'datepicker',
  header: 'datepicker_header',
  footer: 'datepicker_footer',
  preYears: 'datepicker_preYears',
  nextYears: 'datepicker_nextYears',
  years: 'datepicker_years',
  calendar: 'datepicker_calendar',
  date: 'datepicker_date',
  holiday: 'datepicker_holiday',
  ym: 'datepicker_ym',
  table: 'datepicker_table',
  tableTh: 'datepicker_tableTh',
  nextMonthMark: 'datepicker_nextMonthMark',
  nextYearMark: 'datepicker_nextYearMark',
  preMonthMark: 'datepicker_preMonthMark',
  preYearMark: 'datepicker_preYearMark',
  zIndex: null
}
DatePicker.prototype = {
  
  initialize: function(element, target, trigger) {
    this.element = $(element);
    Element.setStyle(this.element, {visibility: 'hidden'});
    this.target = $(target);
    this.date = new Date();

    this.options = Object.extend({
      month: this.date.getMonth() + 1,
      date: this.date.getDate(),
      year: this.date.getFullYear(),
      format: DateUtil.simpleFormat("dd/MM/yyyy"),
      cssPrefix: 'custom_',
      callBack: Prototype.emptyFunction,
      standTo: false,
      beforeShow: Prototype.emptyFunction
    }, arguments[3] || {});
    
    var customCss = CssUtil.appendPrefix(this.options.cssPrefix, DatePicker.className);
    this.classNames = new CssUtil([DatePicker.className, customCss]);
    
    this.format = this.options.format;
    this.callBack = this.options.callBack;
    
    this.date.setMonth(this.options.month - 1);
    this.date.setDate(this.options.date);
    this.date.setFullYear(this.options.year);
    
    this.calendar = this.build();
    this.element.appendChild(this.calendar);
    this.element.appendChild(this.buildExtraButtons()); //XXX Baobab ART
    
    this.doclistener = this.hide.bindAsEventListener(this);
    Event.observe($(trigger), "click", this.show.bindAsEventListener(this));
    this.hide();
    Element.setStyle(this.element, {visibility: 'visible'});
  },
  
  build: function() {
    var node = 
      Builder.node(
        'DIV', 
        {className: this.classNames.joinClassNames('container')},
        [
          this.buildHeader(),
          this.buildCalendar(),
          this.buildFooter()
        ]);
    
    return node;
  },
  
  buildHeader: function() {
    var headerNodes = Builder.node('TR');
    headerNodes.appendChild(this.buildHeaderLeft());
    headerNodes.appendChild(this.buildHeaderCenter());
    headerNodes.appendChild(this.buildHeaderRight());
    
    className = this.classNames.joinClassNames('header');
    var tbody = Builder.node('TBODY', [headerNodes]);
    return Builder.node('TABLE', {className: className}, [tbody]);
  },

  buildFooter: function() {
    var footer = Builder.node('DIV');
    this.classNames.addClassNames(footer, 'footer');
    return footer;
  },

  buildHeaderLeft: function() {
    var container = Builder.node('TD');
    this.classNames.addClassNames(container, 'preYears');

    var id = this.element.id.appendSuffix('preYear');
    var node = Builder.node('DIV', {id: id});
    this.classNames.addClassNames(node, 'preYearMark');
    Event.observe(node, "click", this.changeCalendar.bindAsEventListener(this));
    container.appendChild(node);

    id = this.element.id.appendSuffix('preMonth');
    node = Builder.node('DIV', {id: id});
    this.classNames.addClassNames(node, 'preMonthMark');
    Event.observe(node, "click", this.changeCalendar.bindAsEventListener(this));
    container.appendChild(node);

    return container;
  },

  buildHeaderCenter: function() {
    var contents = [];

    var id = this.element.id.appendSuffix('nextMonth');
    var node = Builder.node('SPAN', {id: id}, [DateUtil.months[this.date.getMonth()]]);
    this.classNames.addClassNames(node, 'ym');
    contents.push(node);

    id = this.element.id.appendSuffix('nextYear');
    node = Builder.node('SPAN', {id: id}, [this.date.getFullYear()]);
    this.classNames.addClassNames(node, 'ym');
    contents.push(node);

    var container = Builder.node('TD', contents);
    this.classNames.addClassNames(container, 'years');

    return container;
  },

  buildHeaderRight: function() {
    var container = Builder.node('TD');
    this.classNames.addClassNames(container, 'nextYears');

    var id = this.element.id.appendSuffix('nextMonth');
    var node = Builder.node('DIV', {id: id});
    this.classNames.addClassNames(node, 'nextMonthMark');
    Event.observe(node, "click", this.changeCalendar.bindAsEventListener(this));
    container.appendChild(node);

    id = this.element.id.appendSuffix('nextYear');
    node = Builder.node('DIV', {id: id});
    this.classNames.addClassNames(node, 'nextYearMark');
    Event.observe(node, "click", this.changeCalendar.bindAsEventListener(this));
    container.appendChild(node);

    return container;
  },
  
  multiBuild: function(tagType, params, className, hover, clickEvent) {
    var children = [];
    for (var i = 0; i < params.length; i++) {
      var node;
      
      node = Builder.node(tagType, [params[i]]);
      if (className)
        this.classNames.addClassNames(node, className);
        
      if (hover)
        new Hover(node);
        
      if (clickEvent)
        Event.observe(node, "click", clickEvent.bindAsEventListener(this));
        
      children.push(node);
    }
    
    return children;
  },
  
  buildCalendar: function() {
    var className = this.classNames.joinClassNames('table');
    var node = Builder.node('TBODY', [this.buildTableHeader(), this.buildTableData()]);
    var table = Builder.node('TABLE', {className: className}, [node]);
                  
    className = this.classNames.joinClassNames('calendar');
    return Builder.node('DIV', {className: className}, [table]);
  },
  
  buildTableHeader: function() {
    var weekArray = new Array();
    var className = this.classNames.joinClassNames('tableTh');
    for (var i = 0; i < DateUtil.dayOfWeek.length; i++) {
      weekArray.push(
        Builder.node('TH', {className: className}, [DateUtil.dayOfWeek[i]]));
    }
    
    return Builder.node('TR', weekArray);
  },
  
  buildTableData: function() {
    var length = DateUtil.dayOfWeek.length * 6;
    var year = this.date.getFullYear();
    var month = this.date.getMonth();
    var firstDay = DateUtil.getFirstDate(year, month).getDay();
    var lastDate = DateUtil.getLastDate(year, month).getDate();
    var trs = new Array();
    var tds = new Array();
    
    for (var i = 0, day = 1; i <= length; i++) {
      if ((i < firstDay) || day > lastDate) {
        tds.push(Builder.node('TD'));
      
      } else {
        var className;
        if ((i % 7 == 0) || ((i+1) % 7 == 0))
          className = 'holiday';
        else
          className = 'date';
          
        var defaultClass = this.classNames.joinClassNames(className);
        node = Builder.node('TD', {className: defaultClass}, [day]);
        new Hover(node);
        Event.observe(node, "click", this.selectDate.bindAsEventListener(this));
        tds.push(node);
        day++;
      }
      
      if ((i + 1) % 7 == 0) {
        trs.push(Builder.node('TR', tds));
        tds = new Array();
      }
    }
    
    return trs;
  },
  
  refresh: function() {
    Element.remove(this.calendar);
    this.calendar = this.build();
    this.element.appendChild(this.calendar);
  },
  
  getMonth: function() {
    return  DateUtil.months[this.date.getMonth()];
  },
  
  changeCalendar: function(event) {
    var element = Event.element(event);
    if (Element.hasClassName(element, DatePicker.className.preYearMark)) {
      this.date.setFullYear(this.date.getFullYear() - 1);
    } else if (Element.hasClassName(element, DatePicker.className.nextYearMark)) {
      this.date.setFullYear(this.date.getFullYear() + 1);
    } else if (Element.hasClassName(element, DatePicker.className.preMonthMark)) {
      var pre = this.date.getMonth() - 1;
      if (pre < 0) {
        pre = 11;
        this.date.setFullYear(this.date.getFullYear() - 1);
      }
      this.date.setMonth(pre);
    } else if (Element.hasClassName(element, DatePicker.className.nextMonthMark)) {
      var next = this.date.getMonth() + 1;
      if (next > 11) {
        next = 0;
        this.date.setFullYear(this.date.getFullYear() + 1);
      }
      this.date.setMonth(next);
    }
    
    this.refresh();
    if (event) Event.stop(event);
  },
  
  selectDate: function(event) {
    var src = Event.element(event);
    var text = Element.getTextNodes(src)[0];

    this.date.setDate(text.nodeValue);
    
    var value = this.format(this.date);
    
    if (this.target.value || this.target.value == '') {
      this.target.value = value;
    } else {
      this.target.innerHTML = value;
    }
    
    this.hide();
    this.classNames.refreshClassNames(src, 'date');
    
    this.callBack(this);
  },
  
  show: function(event) {
    var styles = $H({zIndex: ZindexManager.getIndex(this.options.zIndex)});
    if (this.options.standTo) {
      this.defaultParent = this.element.parentNode;
      document.body.appendChild(this.element);
      var position = Position.cumulativeOffset(document.body);
      styles.merge({ 
        position: 'absolute',
        left:     Event.pointerX(event) - position[0] + 'px',
        top:      Event.pointerY(event) - position[1] + 'px'
      });
    }

    Element.setStyle(this.element, styles);
    Element.show(this.calendar);
    Event.observe(document, "click", this.doclistener);
    if (event) {
      Event.stop(event);
    }
  },
  
  hide: function() {
    Event.stopObserving(document, "click", this.doclistener);
    Element.hide(this.calendar);
    if (this.defaultParent) {
      this.defaultParent.appendChild(this.element);
    }
  },
  
  addTrigger: function(trigger) {
    Event.observe($(trigger), 'click', this.show.bindAsEventListener(this));
  },
  
  changeTarget: function(target) {
    this.target = $(target);
  }
}
