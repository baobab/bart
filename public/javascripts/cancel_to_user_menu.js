function cancelEntry() {
  var inputElements = document.getElementsByTagName("input");
  for (i in inputElements) {
    inputElements[i].value = "";
  }
  //disableTouchscreenInterface();
  //window.location.reload();
  window.location.href = "/user/user_menu";
}

