
function $(anElementId) {
	return document.getElementById(anElementId);
}

function showMessage(aMessage) {
	var messageBar = tstMessageBar;
	messageBar.innerHTML = aMessage;
	if (aMessage.length > 0) { 
    messageBar.style.display = 'block' 
    window.setTimeout("hideMessage()",3000)
	}
}

function hideMessage(){ 
  tstMessageBar.style.display = 'none' 
}

function loadTTLite() {

	inputPage = document.body;

	inputPage.innerHTML += "<div id='messageBar' class='messageBar'></div>"; 
	inputPage.innerHTML += "<div id='confirmationBar' class='touchscreenPopup'></div>"; 
	inputPage.innerHTML += "<div id='keyboard' class='keyboard'></div>"; 
	tstMessageBar = $('messageBar');
	tstKeyboard = $("keyboard");
}

function confirmCancelEntry() {
	tstMessageBar.innerHTML = "Are you sure you want to Cancel?<br/>" +
													  "<button onmousedown='hideMessage(); cancelEntry();'>Yes</button><button onmousedown='hideMessage();'>No</button>";
	tstMessageBar.style.display = "block";
	
}

function cancelEntry() {
	
  var inputElements = document.getElementsByTagName("input");
  for (i in inputElements) {
    inputElements[i].value = "";
  }
  window.location.href = "/patient/menu";
}

function confirmValue(onValidAction) {
	hideMessage();
	var confirmationBar = $("confirmationBar");
	confirmationBar.innerHTML = "Username: ";
	var username = document.createElement("input");
	username.setAttribute("id", "confirmUsername");
	username.setAttribute("type", "text");
	username.setAttribute("textCase", "lower");
	confirmationBar.appendChild(username);

	confirmationBar.innerHTML += "<div style='display: block;'><button class='button' style='float: left;' onmousedown='validateConfirmUsername(\""+ onValidAction +"\")'>OK</button><button class='button' style='float: right; right: 3px;' onmousedown='cancelConfirmValue()'>Cancel</button>";
	
	confirmationBar.style.display = "block";
	tstInputTarget = $("confirmUsername");
	if (typeof(barcodeFocusTimeoutId) != "undefined")
		window.clearTimeout(barcodeFocusTimeoutId);

	setTimeout("tstInputTarget.focus()", 1000);
	
	checkForBarcode("confirmUsername", "validateConfirmUsername(\""+ onValidAction +"\")");
//	tstInputTarget.focus();
	tstKeyboard.innerHTML = getABCKeyboard();
	tstKeyboard.style.display = "block";
}

function validateConfirmUsername(onValidAction) {
	var username = $('confirmUsername');
	if (username.value == tstUsername) {
		eval(onValidAction);

		$("confirmationBar").style.display = "none";
		tstKeyboard.style.display = "none";
		if (typeof(focusForBarcodeInput) != "undefined")
			focusForBarcodeInput();
	} else {
		showMessage("Username entered is invalid");
	}
}

function cancelConfirmValue() {
	$("confirmationBar").style.display = "none";
	tstKeyboard.style.display = "none";
	if (typeof(focusForBarcodeInput) != "undefined")
		focusForBarcodeInput();
}

function getABCKeyboard(){
	var keyboard = 
		"<span class='abcKeyboard'>" +
		"<span class='buttonLine'>" +
		getButtons("ABCDEFGH") +
		getButtonString('backspace','<span>BkSp</span>') +
		getButtonString('num','<span>Num</span>') +
//		getButtonString('date','<span>Date</span>') +
		"</span><span class='buttonLine'>" +
		getButtons("IJKLMNOP") +
		getButtonString('apostrophe',"<span>'</span>") +
		getButtonString('space','<span>Space</span>') +
		getButtonString('SHIFT','<span>SHIFT</span>') +
		getButtonString('Unknown','<span>Unknown</span>') +
		"</span><span class='buttonLine'>" +
		getButtons("QRSTUVWXYZ") +
		getButtonString('qwerty','<span>qwerty</span>') +
		"</span>" +
		"</span>";
	return keyboard;
}

function createKeyboardDiv(){
	var keyboard = $("keyboard");
	if (keyboard) keyboard.innerHTML = "";
	else {
		keyboard = document.createElement("div");
		keyboard.setAttribute('class','keyboard');
		keyboard.setAttribute('id','keyboard');
	}
	return keyboard;
}

function getNumericKeyboard(){
	var keyboard = 
		"<span class='numericKeyboard'>" +
		"<span id='buttonLine1' class='buttonLine'>" +
		getButtons("123") +
		getCharButtonSetID("*","star") +
		getButtonString('abc','<span>abc</span>') +
		getButtonString('date','<span>Date</span>') +
		"</span><span id='buttonLine2' class='buttonLine'>" +
		getButtons("456") +
		getCharButtonSetID("-","minus") +
		getButtonString('qwerty','<span>qwerty</span>') +
		"</span><span id='buttonLine3' class='buttonLine'>" +
		getButtons("789") +
		getCharButtonSetID("+","plus") +
		getButtonString('SHIFT','<span>SHIFT</span>') +
		"</span><span id='buttonLine4' class='buttonLine'>" +
		getCharButtonSetID(".","decimal") +
		getCharButtonSetID("0","zero") +
		getCharButtonSetID("/","slash") +
		getCharButtonSetID(",","comma") +
		getCharButtonSetID("%","percent") +
		getCharButtonSetID("=","equals") +
		getCharButtonSetID("<","lessthan") +
		getCharButtonSetID(">","greaterthan") +
		getButtonString('backspace','<span>BkSp</span>') +
		getButtonString('Unknown','<span>Unknown</span>') +
		"</span>" +
		"</span>"
	return keyboard;
}

function getQwertyKeyboard(){
	var keyboard = createKeyboardDiv();
	keyboard.innerHTML += 
		"<span class='qwertyKeyboard'>" +
		"<span class='buttonLine'>" +
		getButtons("QWERTYUIOP") +
		getButtonString('backspace','<span>BkSp</span>') +
//		getButtonString('date','<span>Date</span>') +
		"</span><span style='padding-left:15px' class='buttonLine'>" +
		getButtons("ASDFGHJKL") +
		getButtonString('space','<span>Space</span>') +
		getButtonString('SHIFT','<span>SHIFT</span>') +
		"</span><span style='padding-left:25px' class='buttonLine'>" +
		getButtons("ZXCVBNM,.") +
		getButtonString('abc','<span>abc</span>') +
		getButtonString('num','<span>Num</span>') +
		"</span>" +
		"</span>"
	return keyboard;
}


function getButtons(chars){
	var buttonLine = "";
	for(var i=0; i<chars.length; i++){
    character = chars.substring(i,i+1)
    buttonLine += getCharButtonSetID(character,character)
	}
	return buttonLine;
}

function getCharButtonSetID(character,id){
	return '<button onMouseDown="press(\''+character+'\');" class="keyboardButton" id="'+id+'">' +character+ "</button>";
}

function getButtonString(id,string){
	return "<button \
		onMouseDown='press(this.id);' \
		class='keyboardButton' \
		id='"+id+"'>"+
		string +
	"</button>";
}

function press(pressedChar){
	inputTarget = tstInputTarget;
	if (pressedChar.length == 1) {
		inputTarget.value += getRightCaseValue(pressedChar);
	} else {
		switch (pressedChar) {
			case 'backspace':
				inputTarget.value = inputTarget.value.substring(0,inputTarget.value.length-1);
				break;
			case 'done':
				touchScreenEditFinish(inputTarget);
				break;
			case 'space':
				inputTarget.value += ' ';
				break;
			case 'apostrophe':
				inputTarget.value += "'";
				break;
			case 'abc':
				tstKeyboard.innerHTML = getABCKeyboard();
				break;
			case 'qwerty':
				tstKeyboard.innerHTML = getQwertyKeyboard();
				break;
			case 'num':
				tstKeyboard.innerHTML = getNumericKeyboard();
				break;
			case 'date':
				getDatePicker();
				break;
			case 'SHIFT':
				toggleShift();
				break;
			case 'Unknown':
				inputTarget.value = "Unknown";
				break;
		
			default:
				inputTarget.value += pressedChar;
		}
	}

}

function getRightCaseValue(aChar) {
	var newChar = '';
	var inputElement = tstInputTarget;
	var fieldCase = inputElement.getAttribute("textCase");

	switch (fieldCase) {
		case "lower":
			newChar = aChar.toLowerCase();
			break;
		case "upper":
			newChar = aChar.toUpperCase();
			break;
		default:		// Capitalise First Letter
			if (inputElement.value.length == 0)
				newChar = aChar.toUpperCase();
			else 
				newChar = aChar.toLowerCase();
	}
	return newChar;
}





window.addEventListener("load", loadTTLite, false);
