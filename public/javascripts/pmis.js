// --------------------------------------------------------------------
// 
// Touchscreen Toolkit
//
// (c) 2006 Baobab Health Partnership www.baobabhealth.org

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

//----------- TODO: delete these after confirmation
/*
function removePx(positionString){
  return positionString.substr(0,positionString.lastIndexOf('px'));
}

function SelectMe(element){
    element.style.backgroundColor = "darkblue";
    element.style.color = "white";
}
// ---------- end to Delete
*/

var tstLastActionTime;  //= null; //new Date();
var tstIdleTimeout; // = null;
var tstIdleTimeoutPeriod = 1800; // idle timeout period in seconds
var tstIdleWarnPeriod = 30; // idle timeout warn period in seconds
tstCancelURL = "/patient/menu?no_auto_load_forms=true";

if (typeof(tstRetrospectiveMode) == "undefined") 
	tstRetrospectiveMode = false;

function validateCD4Keyboard() {
	if (tstInputTarget.value.length < 1) {
		$('decimal').disabled = true;
		$('decimal').style.color = "gray";

		$('zero').disabled = true;
		$('zero').style.color = "gray";
		for (var i=1; i<10; i++) {
			$(i).disabled = true;
			$(i).style.color = "gray";
		}

		$('equals').disabled = false;
		$('lessthan').disabled = false;
		$('greaterthan').disabled = false;
		
		$('equals').style.color = "black";
		$('lessthan').style.color = "black";
		$('greaterthan').style.color = "black";
	} else {
		$('decimal').disabled = false;
		$('decimal').style.color = "black";
		$('zero').disabled = false;
		$('zero').style.color = "black";
		for (var i=1; i<10; i++) {
			$(i).disabled = false;
			$(i).style.color = "black";
		}
		
		$('equals').disabled = true;
		$('lessthan').disabled = true;
		$('greaterthan').disabled = true;
		
		$('equals').style.color = "gray";
		$('lessthan').style.color = "gray";
		$('greaterthan').style.color = "gray";
	}
}

/* Customize Provider observation page */
function customizePage() {
	var formElement = tstFormElements[tstPages[tstCurrentPage]];
	if (formElement.id == tstProviderId) {	// Provider
		$("keyboard").style.display = "block";
		$("viewport").style.display = "none";
		tstInputTarget.style.display = "block";
		tstInputTarget.style.top = "120px";
		formElement.setAttribute("allowFreeText", "true");
		tstInputTarget.setAttribute("textCase", "lower");
	}
}

function testPress(pressedChar) {
	setTimeout('press(\"'+pressedChar+'\")', 2000);
}

function getMinMaxValues() {
  var yr = document.getElementsByName('observation[date:143(1i)]')[0]
  var month = document.getElementsByName('observation[date:143(2i)]')[0]
  var dy = document.getElementsByName('observation[date:143(3i)]')[0]

  var aUrl="" 
  if (yr && month && dy) {
    aUrl="/patient/validate_weight_height?dateValue="+dy.value+'/'+month.value+'/'+yr.value
  }
  var validValues=null
  var httpRequest = new XMLHttpRequest(); 
  httpRequest.onreadystatechange = function() { 
    if (httpRequest.readyState == 4 && httpRequest.status == 200) {
    validValues=handleValidRange(httpRequest);
    if (tstInputTarget.name=="observation[number:6]"){ 
      tstInputTarget.setAttribute('min', validValues.min_height)
      tstInputTarget.setAttribute('max', validValues.max_height)
    } else if (tstInputTarget.name=="observation[number:100]"){
      tstInputTarget.setAttribute('min', validValues.min_weight)
      tstInputTarget.setAttribute('max', validValues.max_weight)
    }
    tstInputTarget.removeAttribute("optional")
    }
  };
  try {
    httpRequest.open('GET', aUrl, true);
    httpRequest.send(null);    
  } catch(e){
  }

  return true
}
function handleValidRange(aXMLHttpRequest) {
  var validRange=null
	if (!aXMLHttpRequest) return validRange;
  
  if (aXMLHttpRequest.readyState == 4 && aXMLHttpRequest.status == 200) {
    validRange= eval('('+aXMLHttpRequest.responseText+')');
  }
  return validRange;
}


function updateHeartbeat() {
  /*
	var thisTime = new Date()
	var beatTime = ""+thisTime.getFullYear()
	beatTime += ""+thisTime.getMonth()+1
	beatTime += ""+thisTime.getDate()
	beatTime += "_"+thisTime.getHours()
	beatTime += ":"+thisTime.getMinutes()
	beatTime += ":"+thisTime.getSeconds()
  */

	var username = typeof(tstUsername) == "undefined"? "" : tstUsername

	var params = "";
	params += "url="+window.location
	params += "&username="+username
//	params += "&time="+beatTime

	ajaxRequest(null, "/heartbeat/update?"+params)
	setTimeout("updateHeartbeat()", 300000); // ms == 5mins
}

function resetLastActionTime() {
	tstLastActionTime = new Date();
	clearTimeout(tstIdleTimeout);
	tstIdleTimeout = setTimeout("checkIdleTimeout()", tstIdleTimeoutPeriod*1000);
}

function checkIdleTimeout() {
	var timeoutTime = new Date(tstLastActionTime);
	timeoutTime.setSeconds(timeoutTime.getSeconds() + tstIdleTimeoutPeriod + tstIdleWarnPeriod)
	var now = new Date();
	var secsRemaining = Math.round((timeoutTime - now)/1000);
	if (secsRemaining <= tstIdleWarnPeriod) {
		tstMessageBar.innerHTML = "System will log you out in " + secsRemaining + " secs.. <br/>" + 
		                           "<button onmousedown='hideMessage(); resetLastActionTime();'>Cancel</button>"
		tstMessageBar.style.display = 'block';

		if (secsRemaining > 0 ) {
			clearTimeout(tstIdleTimeout);
			tstIdleTimeout = setTimeout("checkIdleTimeout()", 1000);
		} else {
			window.location.href="/user/logout";
		}
	} else {
		tstMessageBar.innerHTML = "";
		clearTimeout(tstIdleTimeout);
		tstIdleTimeout = setTimeout("checkIdleTimeout()", tstIdleTimeoutPeriod*1000);
	}
}

function initBART() {
	setTimeout("updateHeartbeat()", 30000); // ms == 30secs
	if (tstIdleTimeout != null) {
		clearTimeout(tstIdleTimeout);
	}
	tstIdleTimeout = setTimeout("checkIdleTimeout()", tstIdleTimeoutPeriod*1000);
	document.body.addEventListener("mousedown", resetLastActionTime, false)
	resetLastActionTime();
}

function ajaxJavascriptRequest(aUrl,aFunction) {
  var httpRequest = new XMLHttpRequest(); 
  httpRequest.onreadystatechange = function() { 
    if (httpRequest.readyState == 4 && httpRequest.status == 200) {
      if (aFunction){  
        aFunction(httpRequest.responseText);
      }else{
        eval(httpRequest.responseText);
      }
    }
  };
  try {
    httpRequest.open('GET', aUrl, true);
    httpRequest.send(null);    
  } catch(e){
  }
}

function skipMissingData() {
	hideMessage();
  tstFormElements[tstPages[tstCurrentPage]].innerHTML += "<option value='Missing'>Missing</option>"
	tstInputTarget.value = "Missing";
	gotoPage(tstCurrentPage+1, false);
}

TTInput.prototype.validateExistence = function(){	
		// check for existence
		if (this.value.length<1 && this.element.getAttribute("optional") == null) {
			var missingDisabled = tstInputTarget.getAttribute("tt_missingDisabled");
			if (tstRetrospectiveMode == "true" && !missingDisabled) {
				return "Is Data Missing?<br/> <button onmousedown='skipMissingData();'>Yes</button><button onmousedown='hideMessage();'>No</button>"
			} else {
				return "You must enter a value to continue";
			}
		}
		
		return "";
}



window.addEventListener("load", initBART, false)


