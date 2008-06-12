/*
window.setTimeout(find_selectable_tables, 1000)

function find_selectable_tables(){
  tables = document.getElementsByTagName('table');
  for(var i=0; i < tables.length; i++){
    console.log (tables[i].className)
    if (tables[i].className.search(/\bselectable\b/) != -1) {
      addMousedownEvents(tables[i]);
    }
  };
}
*/

function addMousedownEvents(){
  trs = document.getElementsByTagName("tr")
  for(var i=0; i < trs.length; i++){
    trs[i].setAttribute("onmousedown", "selectRow(this)");
  }
}


function selectElement(element){
  clearBackgroundColor()
  clickedClass = element.className
  elements = document.getElementsByTagName("td")
  for(i=0;i<elements.length;i++){
    if(elements[i].className == clickedClass)
      elements[i].style.backgroundColor='ffff99'
  }
  highlightRow(element.parentNode)
  element.style.backgroundColor = "lightgreen"
}

function selectRow(row){
  clearBackgroundColor()
  highlightRow(row)
}

function highlightRow(row){
  row.style.backgroundColor = "lightblue"
}

function clearBackgroundColor(){
  rows = document.getElementsByTagName("tr")
  for(i=0;i<rows.length;i++){
    rows[i].style.backgroundColor=''
  }
  elements = document.getElementsByTagName("td")
  for(i=0;i<elements.length;i++){
    elements[i].style.backgroundColor=''
  }
}
