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
  //disableTouchscreenInterface();
  //window.location.reload();
  
  window.location.href = "/user/activities";
}

