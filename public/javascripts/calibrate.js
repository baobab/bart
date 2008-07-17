var calibration_enabled = false;
var disable_capture = false;
var calibrate_x = -100;
var calibrate_y = -100;

if (document.addEventListener) {
  document.addEventListener("DOMContentLoaded", enable_calibration, false);
}


function enable_calibration() {
  try {
    netscape.security.PrivilegeManager.enablePrivilege('UniversalXPConnect');
    netscape.security.PrivilegeManager.enablePrivilege('UniversalBrowserWrite');
    calibration_enabled = true;
    create_overlay();
  } catch(e) {
    if (console) 
      console.error("Calibration privileges are not enabled for this domain\n"+
                   "To enable these privileges, go to http://about:config in your browser and make the following changes:\n"+
                   "  signed.applets.codebase_principal_support: true\n" +
                   "  capability.principal.codebase.p1.granted: UniversalXPConnect UniversalBrowserWrite\n"+
                   "  capability.principal.codebase.p1.id: " + window.location.protocol + "//" + window.location.host);
  }    
}

function create_overlay() {
  div = document.createElementNS("http://www.w3.org/1999/xhtml", "div");
  div.id = "overlay"
  div.setAttribute("onmouseup", "overlay_mouseup(event);");
  document.body.appendChild(div);
}

function overlay_mouseup(evt) {
  if (!calibration_enabled) return;
  if (disable_capture) return;
  evt.preventDefault();
  evt.stopPropagation();      
  disable_capture = true;
  overlay = document.getElementById("overlay"); 
  overlay.style.height = 0;
  x = calibrate_x + evt.clientX;
  y = calibrate_y + evt.clientY;
  setTimeout("window_click(" + x + "," + y + ");", 1);
}  

function window_click(x, y) {
  netscape.security.PrivilegeManager.enablePrivilege('UniversalXPConnect');
  netscape.security.PrivilegeManager.enablePrivilege('UniversalBrowserWrite');
  var req = window.QueryInterface(Components.interfaces.nsIInterfaceRequestor);
  var utils = req.getInterface(Components.interfaces.nsIDOMWindowUtils);
  utils.sendMouseEvent("mousedown", x, y, 0, 1, 0); 
  utils.sendMouseEvent("mouseup", x, y, 0, 1, 0); 
  overlay = document.getElementById("overlay"); 
  overlay.style.height = 800;
  disable_capture = false;
}