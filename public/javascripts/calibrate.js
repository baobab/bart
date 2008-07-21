// Eventually move this out to an in page block
var calibration_setup = true;

// Screen dimensions
var resolution_width = 800;
var resolution_height = 600;

// Calibration initialization
var calibration = []
calibration[0] = {x: 0, y: 0};
calibration[1] = {x: resolution_width, y: 0};
calibration[2] = {x: 0, y: resolution_height};
calibration[3] = {x: resolution_width, y: resolution_height};
var calibration_index = 0
var calibration_matrix;

var calibration_targets = []
calibration_targets[0] = {x: 10, y: 10};
calibration_targets[1] = {x: resolution_width - 30, y: 10};
calibration_targets[2] = {x: 10, y: resolution_height - 30};
calibration_targets[3] = {x: resolution_width - 30, y: resolution_height - 30};

var calibration_enabled = false;
var disable_capture = false;

if (document.addEventListener) {
  document.addEventListener("DOMContentLoaded", enable_calibration, false);
}

// Calibration will only be enabled for Firefox/Mozilla Browsers
// Additionally Universal privileges must be available
function enable_calibration() {
  if (!calibration_setup) return;
  try {
    netscape.security.PrivilegeManager.enablePrivilege('UniversalXPConnect');
    netscape.security.PrivilegeManager.enablePrivilege('UniversalBrowserWrite');
    calibration_enabled = true;
    create_calibration_setup();
    create_overlay();
  } catch(e) {
    if (console) 
      console.error("Calibration privileges are not enabled for this domain\n"+
                    "To enable these privileges, go to about:config in your browser and make the following changes:\n"+
                    "  signed.applets.codebase_principal_support: true\n" +
                    "  capability.principal.codebase.p1.granted: UniversalXPConnect UniversalBrowserWrite\n"+
                    "  capability.principal.codebase.p1.id: " + window.location.protocol + "//" + window.location.host);
  }    
}

// Setup the calibration for the current index in the calibration array with the supplied coordinate
function calibrate(x, y) {
  calibration[calibration_index++] = {x: x, y: y};
  if (calibration_index > 3) {
    calculate_calibration_matrix();
    return;
  }  
  calibrate_hit_target = document.getElementById('calibrate_hit_target');
  calibrate_hit_target.style.left = calibration_targets[calibration_index].x + 'px';
  calibrate_hit_target.style.top = calibration_targets[calibration_index].y + 'px';
}

// Build a matrix for calibration adjustments based on the setup
// TODO: Check the bounds
// TODO: Add an average for the fourth point which is currently unused
// TODO: The scale could be averaged against all points
// TODO: The translation could be averaged against all points
function calculate_calibration_matrix() {
  try {
    calibration_index = 0;
    calibration_matrix = create_matrix();
    calibration_matrix = calibration_matrix.translate(- (calibration[0].x - 30), - (calibration[0].y - 30));
    calibration_matrix = calibration_matrix.scaleNonUniform((resolution_width - 30) / (calibration[1].x - calibration[0].x), (resolution_height - 30) / (calibration[2].y - calibration[0].y));
    calibration_setup = false;
    calibrate = document.getElementById('calibrate');
    document.body.removeChild(calibrate)
  } catch(e) {
    if (console)
      console.error("Could not build the calibration matrix: " + e.message);
  }
}

function create_overlay() {
  div = document.createElementNS("http://www.w3.org/1999/xhtml", "div");
  div.id = "overlay"
  div.setAttribute("onmouseup", "overlay_mouseup(event);");
  document.body.appendChild(div);
}
    
function create_calibration_setup() {
  div = document.createElementNS("http://www.w3.org/1999/xhtml", "div");
  div.id = "calibrate"
  calibrate_hit_target = document.createElementNS("http://www.w3.org/1999/xhtml", "div");
  calibrate_hit_target.id = "calibrate_hit_target"
  calibrate_hit_target.style.left = calibration_targets[calibration_index].x + 'px';
  calibrate_hit_target.style.top = calibration_targets[calibration_index].y + 'px';
  document.body.appendChild(div);
  div.appendChild(calibrate_hit_target);
}
    

// Handle the mouse button up on the overlay; adjust it and pass it through
function overlay_mouseup(evt) {
  if (!calibration_enabled) return;
  if (calibration_setup) {
    calibrate(evt.clientX, evt.clientY);
    evt.preventDefault();
    evt.stopPropagation();      
    return;
  }
  if (disable_capture) return;
  evt.preventDefault();
  evt.stopPropagation();      
  disable_capture = true;
  overlay = document.getElementById("overlay"); 
  overlay.style.height = 0;
  var point = create_point(evt.clientX, evt.clientY);
  point = point.matrixTransform(calibration_matrix);
  setTimeout("window_click(" + (point.x) + "," + (point.y) + ");", 1);
}  

function window_click(x, y) {
  netscape.security.PrivilegeManager.enablePrivilege('UniversalXPConnect');
  netscape.security.PrivilegeManager.enablePrivilege('UniversalBrowserWrite');
  var req = window.QueryInterface(Components.interfaces.nsIInterfaceRequestor);
  var utils = req.getInterface(Components.interfaces.nsIDOMWindowUtils);
  utils.sendMouseEvent("mousedown", x, y, 0, 1, 0); 
  utils.sendMouseEvent("mouseup", x, y, 0, 1, 0); 
  overlay = document.getElementById("overlay"); 
  overlay.style.height = resolution_height + 'px';
  disable_capture = false;
}


// Utilize SVG matrices for vector transformation (virtual touchscreen to actual)
function create_matrix() {
  return document.createElementNS("http://www.w3.org/2000/svg", "svg").createSVGMatrix();      
}

// Utilize SVG points for coordinates
function create_point(x,y) {
  var point = document.createElementNS("http://www.w3.org/2000/svg", "svg").createSVGPoint();      
  point.x = x;
  point.y = y;
  return point;
}