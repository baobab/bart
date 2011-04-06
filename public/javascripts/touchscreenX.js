var drug_selected = null
function createExtras(){
  for(i=0 ; i < drugs.length ; i++){
    sValue = document.getElementById("option" + drugs[i])
    sValue.setAttribute("onmousedown","selectedDrug('" + drugs[i] +"');updateTouchscreenInputForSelect(this);")
  }

  //document.getElementById('buttons').setAttribute("style","right:30px;top:0px;");
  document.getElementById('buttons').setAttribute("style","right:10px;top:0px;display:block;position:absolute;z-index:10;");
  document.getElementById("viewport").setAttribute("style","width:40%;top:12px;")
  document.getElementById("page" + tstCurrentPage).setAttribute("style","width:1250px;")
  var next_page = (parseFloat(tstCurrentPage) - 1)
  document.getElementById("backButton").setAttribute("onmousedown","gotoPage('" + next_page + "');resetForm();")
  document.getElementById("nextButton").setAttribute("onmousedown","validatePage()")

  var viewPortx = document.createElement("div")
  viewPortx.setAttribute('id','xviewport')
  viewPortx.setAttribute('class','options')
  
  var xoptions = document.createElement("div");
  xoptions.setAttribute('id','options');
  xoptions.setAttribute('class','scrollable');

  viewPortx.appendChild(xoptions) 

  var ul = document.createElement("ul")
  ul.id = "secondUl"

  xoptions.appendChild(ul)

  document.getElementById("page" + tstCurrentPage).setAttribute("style","width:1200px;")
  document.getElementById("load_indicator").setAttribute("style","display:none;")
  document.getElementById("page" + tstCurrentPage).appendChild(viewPortx)
  document.getElementsByClassName("inputPage")[0].setAttribute("style","width:100%;")

// The following code adds dosage to right div
  dosages = ["Morning 1","Noon 1","Evening 1","Night 1","Morning 0.5","Noon 0.5","Evening 0.5","Night 0.5","Morning 0.75","Noon 0.75","Evening 0.75","Night 0.75","Morning 2","Noon 2","Evening 2","Night 2"]
  var select = document.createElement("input")
  select.setAttribute("type","select")
  select.setAttribute("id","dosages")
  select.setAttribute("helpText","Dosages")
  select.setAttribute("multiple","multiple")
  document.getElementById("page" + tstCurrentPage).appendChild(select)

  for(i = 0 ; i < dosages.length ; i++){
    var li = document.createElement("li")
    li.innerHTML = dosages[i]
    li.setAttribute("onmousedown","addDosage(this);")
    li.setAttribute("class","dosages")
    li.setAttribute("id",dosages[i].sub(" ","_").sub("0.","0_"))
    document.getElementById("secondUl").appendChild(li)
  }


  var inputTarget = tstInputTarget;
  updateTouchscreenInputForSelect = function(element) {
    var multiple = inputTarget.getAttribute("multiple") == "multiple";
    
    //inputTarget.value = val_arr.join(tstMultipleSplitChar);
    selectionHighlight(element.parentNode.childNodes, inputTarget)
  }

  gotoNextPage = function() {
  if (tstInputTarget.getAttribute("tt_requireNextClick") != "false")
    tstNextButton.style.backgroundColor = "lightblue";
    gotoPage(tstCurrentPage+1, false);
  }
  

   clearInput = function() {
    document.getElementById('touchscreenInput'+tstCurrentPage).value = "";
    dos = document.getElementsByClassName('dosages')
    for(i = 0 ; i < dos.length ; i++){
      dos[i].style.backgroundColor = ""
    }

    for(i = 0 ; i < drugs.length ; i++){
      arv_drugs[drugs[i]] = 1
      document.getElementById("option" + drugs[i]).style.backgroundColor = ""
    }

  }

  if(document.getElementById("selected_dosage").value){
    last_drug_selected = null
    dosages = document.getElementById("selected_dosage").value.split(',')
    for(i = 0 ; i < dosages.length ; i++){
     drug_name =  dosages[i].split(':')[0] ; dos =  dosages[i].split(':')[1]
     last_drug_selected = drug_name
     document.getElementById("option" + drug_name).style.backgroundColor = "lightgrey"
     selected_dos = dosages[i].split(':')[1]
     arv_drugs[drug_name] = selected_dos
    }
    document.getElementById("option" + last_drug_selected).style.backgroundColor = "lightblue"
    last_dosages_selected = arv_drugs[last_drug_selected].split(';')
    for(i = 0 ; i < last_dosages_selected.length ; i++){
      document.getElementById(last_dosages_selected[i].sub(" ","_").sub("0.","0_")).style.backgroundColor = "lightgreen"
    }
  }

}

function selectionHighlight(options, inputElement){
  for(i = 0 ; i < drugs.length ; i++){
    if(document.getElementById("option" + drugs[i]).style.backgroundColor && arv_drugs[drugs[i]] == 1)
      document.getElementById("option" + drugs[i]).style.backgroundColor = ""
  }

  dos = document.getElementsByClassName('dosages')
  for(i = 0 ; i < dos.length ; i++){
    dos[i].style.backgroundColor = ""
  }

  if(document.getElementById("option" + drug_selected).style.backgroundColor == 'lightgrey' && arv_drugs[drug_selected] != 1){
    for(i = 0 ; i < options.length ; i++){
      if(options[i].style.backgroundColor){
        if (arv_drugs[options[i].id.sub("option",'')] != 1){
          options[i].style.backgroundColor = "lightgrey"
        }else{options[i].style.backgroundColor = ""}
      }
    }
    document.getElementById("option" + drug_selected).style.backgroundColor = "lightblue"
    dosage_arr = arv_drugs[drug_selected].split(';')
    for(var i = 0 ; i < dosage_arr.length ; i++){
      for(var x = 0 ; x < dos.length ; x++){
        if(document.getElementById(dos[x].id).innerHTML == dosage_arr[i])
          document.getElementById(dos[x].id).style.backgroundColor = "lightgreen"
      }
    }
    return
  }else if(document.getElementById("option" + drug_selected).style.backgroundColor && arv_drugs[drug_selected] != 1){
    arv_drugs[drug_selected] = 1
  }

  if(document.getElementById("option" + drug_selected).style.backgroundColor){
    document.getElementById("option" + drug_selected).style.backgroundColor = ""
    updateInputTarget()
    return
  }

  for(i = 0 ; i < options.length ; i++){
    if(options[i].style.backgroundColor){
      if (arv_drugs[options[i].id.sub("option",'')] != 1){
        options[i].style.backgroundColor = "lightgrey"
      }else{
        options[i].style.backgroundColor = ""
      }
    }
  }
  document.getElementById("option" + drug_selected).style.backgroundColor = "lightblue"
}


function addDosage(dosage){
  if(!drug_selected)
    return

  if(document.getElementById(dosage.id).style.backgroundColor){
    document.getElementById(dosage.id).style.backgroundColor = ""
    dosage_arr = arv_drugs[drug_selected].split(';')
    dosage_arr = removeFromArray(dosage_arr,dosage.innerHTML)
    arv_drugs[drug_selected] = dosage_arr.join(';')
    if(arv_drugs[drug_selected] == "")
      arv_drugs[drug_selected] = 1

    updateInputTarget();
    return
  }

  document.getElementById(dosage.id).style.backgroundColor = "lightgreen"
  dosage_arr = []
  if(arv_drugs[drug_selected] == 1){
    dosage_arr.push(dosage.innerHTML)
    arv_drugs[drug_selected] = dosage_arr.join(';')
  }else{
    dosage_arr = arv_drugs[drug_selected].split(';')
    dosage_arr.push(dosage.innerHTML)
    arv_drugs[drug_selected] = dosage_arr.join(';')
  }
  updateInputTarget();
}

 
function updateInputTarget(){
  input_target = ''
  for (name in arv_drugs) {
    if(arv_drugs[name]!= 1)
      input_target+= name + ":" + arv_drugs[name] + ","
  }
  tstInputTarget.value = input_target.substring(0,(input_target.length - 1))
  document.getElementById("selected_dosage").value =  tstInputTarget.value
}

function selectedDrug(drug){
 drug_selected = drug
}

function validatePage(){
  if (document.getElementById("selected_dosage").value != ""){
    gotoNextPage();
    resetForm();
  }
}


function resetForm(){

  clearInput = function() {
    $('touchscreenInput'+tstCurrentPage).value = "";
    if(doListSuggestions){
      listSuggestions(tstCurrentPage);
    }
  }

  gotoNextPage = function() {
    if (tstInputTarget.getAttribute("tt_requireNextClick") != "false" )
    tstNextButton.style.backgroundColor = "lightblue";
    gotoPage(tstCurrentPage+1, true);
  }

  updateTouchscreenInputForSelect = function(element) {
    var inputTarget = tstInputTarget;
    var multiple = inputTarget.getAttribute("multiple") == "multiple";

    if (multiple) {
      var val_arr = inputTarget.value.split(tstMultipleSplitChar);
      var val = "";
      if (element.value.length>1)
        val = element.value;
        //njih
      else if (element.innerHTML.length>1)
        val = unescape(element.innerHTML);
        // Check if the item is already included  
        //var idx = val_arr.toString().indexOf(val);        
        var idx = (val_arr.join(';')+';').indexOf(val+';');
        if (idx == -1)
          val_arr.push(val);
        else
          //val_arr.splice(idx, 1);  
          val_arr = removeFromArray(val_arr, val);
          inputTarget.value = val_arr.join(tstMultipleSplitChar);
        if (inputTarget.value.indexOf(tstMultipleSplitChar) == 0)
          inputTarget.value = inputTarget.value.substring(1, inputTarget.value.length);
    } else {
      if (element.value.length>0)
        inputTarget.value = element.value;
      else if (element.innerHTML.length>0)
        inputTarget.value = element.innerHTML;
    } 

    highlightSelection(element.parentNode.childNodes, inputTarget)
    tt_update(inputTarget);
    checkRequireNextClick();
  }

  document.getElementById('buttons').setAttribute("style","right:10px;top:0px;display:block;height:250px;position:absolute;z-index:10;");
  document.getElementById("viewport").setAttribute("style","font-size:25px;")
  document.getElementById("page" + tstCurrentPage).setAttribute("style","width:100%;")
  var next_page = (parseFloat(tstCurrentPage) - 1)
  document.getElementById("backButton").setAttribute("onmousedown","gotoPage(" + next_page + ")")
  document.getElementById("nextButton").setAttribute("onmousedown","gotoNextPage()")
  //document.body.removeChild($("xviewport"))
  tstCurrentPage = parseFloat(tstCurrentPage)
}
