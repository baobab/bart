var gDrug = null;

function authorizeNewDrug(gDrug) {
	var message = gDrug[2] + " was not prescribed";
	message += " <a onmousedown='javascript:confirmValue(\"dispenseDrug(gDrug);\")' href='javascript:;'><u>Authorise</u></a> ";
	showMessage(message);
}

function authorizeExceedNeededQty(gDrug) {
	var message = gDrug[1] + " unit" + (parseInt(gDrug[1]) > 1 ? "s" : "")  + " of " + gDrug[2]  + " will exceed the required amount";
	message += " <a onmousedown='javascript:confirmValue(\"dispenseDrug(gDrug);\")' href='javascript:;'><u>Authorise</u></a> ";
	showMessage(message);
}

function barcodeScanAction() {
	var barcodeForm = document.getElementById("barcodeForm");
	var barcodeElement = document.getElementById("barcode");
	var barcodeValue = barcodeElement.value;

	
	if (barcodeDrugs[barcodeValue]) 
		var drugId = barcodeDrugs[barcodeValue][0] || null;
	else
		var drugId = null;

	if (!drugId) {
		showMessage("Scanned drug is not recognised<br/><a style='font-size:30px;text-decoration: underline' href='/drug_barcode/new?barcode="+barcodeValue+"'>touch here to add new drug</a>");
		barcodeElement.value = "";
		window.setTimeout("checkForBarcode()", checkForBarcodeTimeout);
		return;
	}

	if (barcodeDrugs[barcodeValue][1] < 1) {
		showMessage("Scanned drug does not have number of units in system");
		barcodeElement.value = "";
		window.setTimeout("checkForBarcode()", checkForBarcodeTimeout);
		return;
	}
	
	gDrug = barcodeDrugs[barcodeValue]; // [0] id; [1] qty; [2] name 
	
	var drugElement = document.getElementById("drug_"+drugId);
	if (!drugElement) {
		authorizeNewDrug(gDrug);
	} else if (neededQtyExceeded(gDrug)) {
			authorizeExceedNeededQty(gDrug);
	} else {
		incrementFormDispensation(gDrug);
		incrementDisplayValues(gDrug);
	}
			
	barcodeElement.value = "";
  window.setTimeout("checkForBarcode()", checkForBarcodeTimeout);
}

function neededQtyExceeded(aDrug) {
	if (aDrug[1] < 1) return false;

	var inputDrugQtyElement = document.getElementById("inputDrug_"+aDrug[0]+"_qty");
	var drugElement = document.getElementById("drug_"+aDrug[0]);

	var dispensedQty = 0;
	if (inputDrugQtyElement && !isNaN(inputDrugQtyElement.value))
		dispensedQty = parseFloat(inputDrugQtyElement.value);

	if (drugElement && !isNaN(drugElement.getAttribute("dispensedQuantity")))
		dispensedQty += parseFloat(drugElement.getAttribute("dispensedQuantity"))

	var neededQty = 0;
	if (drugElement && !isNaN(drugElement.getAttribute("drugQty")))
		neededQty = parseFloat(drugElement.getAttribute("drugQty"))

	var tabletsPerPack = aDrug[1];
	var neededPacks = Math.ceil(neededQty / tabletsPerPack);
	var dispensedPacks = Math.ceil(dispensedQty / tabletsPerPack);

	// if number of packs to be dispensed exceeds number of packs needed; return true
	if (dispensedPacks + 1 > neededPacks)
		return true;
	else
		return false;
}

function dispenseDrug(aDrug) {
	var drugId = aDrug[0];
	var drugQty = aDrug[1];
	var drugName = aDrug[2];
	var drugElement = document.getElementById("drug_"+drugId);

	if (!drugElement) {
		var drugsTable = document.getElementById("drugsTable");
		drugsTable.innerHTML = drugsTable.innerHTML + "<tr id='drug_" + drugId +
														"'><td></td>" +
														"<td class='drug_name'>"+drugName+"</td>" +
														"<td id='drug_"+drugId+"_dispensedQty' align='right'>0</td>" +
														"<td id='drug_"+drugId+"_dispensedPacks' align='right'></td></tr>";
	}
	incrementFormDispensation(aDrug);
	incrementDisplayValues(aDrug);
}

function incrementFormDispensation(aDrug) {
	// increment Qty (# of tablets) to submitted
	var drugId = aDrug[0];
	var drugQty = aDrug[1];
	var drugName = aDrug[2];
	
	var barcodeForm = document.getElementById("barcodeForm");
	var inputDrugElement = document.getElementById("inputDrug_"+drugId+"_qty");
	var inputDrugPacksElement = document.getElementById("inputDrug_"+drugId+"_packs");
	var currentQty = 0;
	var newQty = drugQty;
	var packCount = Math.ceil(newQty / drugQty);
	if (inputDrugElement && !isNaN(inputDrugElement.value)) {
		currentQty = parseFloat(inputDrugElement.value);
		newQty = currentQty + drugQty;
		packCount = Math.ceil(newQty / drugQty);

		inputDrugElement.value = newQty;
		inputDrugElement.setAttribute("value", newQty);
		inputDrugPacksElement.setAttribute("value", packCount);
	} else {
		barcodeForm.innerHTML += ' <input type="hidden" id="inputDrug_'+drugId+'_qty" name="dispensed['+drugId+'][quantity]" value="'+ newQty +'">';
		barcodeForm.innerHTML += ' <input type="hidden" id="inputDrug_'+drugId+'_packs" name="dispensed['+drugId+'][packs]" value="'+ packCount +'">';
	}
}

function incrementDisplayValues(aDrug) {
	// increment Qty (# of tablets) displayed
	var drugId = aDrug[0];
	var drugQty = aDrug[1];
	var drugName = aDrug[2];

	var inputDrugElement = document.getElementById("inputDrug_"+drugId+"_qty");
	
	var newQty = drugQty;
	if (inputDrugElement && !isNaN(inputDrugElement.value)) {
		newQty = parseFloat(inputDrugElement.value);
	}

	var drugElement = document.getElementById("drug_"+drugId);
	var drugQtyElement = document.getElementById("drug_"+drugId+"_dispensedQty");
	var dispensedQuantity = 0;
	var dispensedQuantityAttr = drugElement.getAttribute("dispensedQuantity");
	if (dispensedQuantityAttr && !isNaN(dispensedQuantityAttr)) {
		dispensedQuantity = parseFloat(dispensedQuantityAttr)
	}

	drugQtyElement.innerHTML = newQty + dispensedQuantity;

	if (drugElement.style.backgroundColor != 'lightblue') {
		var drugColums = drugElement.getElementsByTagName("td");
		for (var i=0; i<drugColums.length; i++) {
			drugColums[i].style.backgroundColor = 'lightblue';
		}
	}

	// refresh # of Packs displayed
	var drugPacksElement = document.getElementById("drug_"+drugId+"_dispensedPacks");
	drugPacksElement.innerHTML = Math.ceil((newQty + dispensedQuantity) / drugQty);

}

function finishDispensation() {
	if (lessDrugsDispensed()) {
		authorizeLessDrugs();
	} else {
		document.forms[0].submit();
	}
}

function lessDrugsDispensed() {
	for (drugId in patientPrescriptions) {
		// TODO: replace DOM ID lookups with faster method e.g. document.forms[0].name
		
		var inputDrugElement = document.getElementById("inputDrug_"+drugId+"_qty");
		var displayDrugElement = document.getElementById("drug_"+drugId);
		var prevDispensedQty = 0;
		if (displayDrugElement) 
			prevDispensedQty = displayDrugElement.getAttribute("dispensedquantity")
/*
		if (!inputDrugElement && !displayDrugElement) {
			return true;
		} else if (inputDrugElement && inputDrugElement.value < patientPrescriptions[drugId]) {
			alert(inputDrugElement.value +" < " + patientPrescriptions[drugId])
			return true;
		}
*/
		var currentDispenseQty = 0;
		var previousDispenseQty = 0;
		if (inputDrugElement && !isNaN(inputDrugElement.value))
			currentDispenseQty = parseFloat(inputDrugElement.value)

		if (displayDrugElement && !isNaN(displayDrugElement.getAttribute("dispensedquantity"))) 
			previousDispenseQty = parseFloat(displayDrugElement.getAttribute("dispensedquantity"))

		if (previousDispenseQty + currentDispenseQty < patientPrescriptions[drugId])
			return true;
			
	}
	return false;
}

function authorizeLessDrugs() {
	var message = "Prescription not completed";
	message += " <a onmousedown='javascript:confirmValue(\"document.forms[0].submit();\")' href='javascript:;'><u>Authorise</u></a> ";
	showMessage(message);
}
